import Foundation
import CloudKit
import MnemoCore

/// Handles CloudKit record storage for backup manifests and encrypted payloads.
/// Uses the user's private CloudKit database: Mnemo never has access to the data.
/// The backup lives in the user's own iCloud storage.
public final class CloudKitBackupStore: @unchecked Sendable {

    private static let containerIdentifier = "iCloud.com.thinkact.mnemo"
    private static let manifestRecordType = "MnemoBackupManifest"

    private let container: CKContainer
    private var database: CKDatabase {
        container.privateCloudDatabase
    }

    public init() {
        self.container = CKContainer(identifier: Self.containerIdentifier)
    }

    public func upload(
        manifest: BackupManifest,
        encryptedPayload: Data
    ) async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(manifest.id.uuidString + ".mnemo")
        try encryptedPayload.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let asset = CKAsset(fileURL: tempURL)
        let manifestData = try JSONEncoder().encode(manifest)

        let record = CKRecord(
            recordType: Self.manifestRecordType,
            recordID: CKRecord.ID(recordName: manifest.id.uuidString)
        )
        record["manifestData"] = manifestData as NSData
        record["payload"] = asset
        record["createdAt"] = manifest.createdAt as NSDate
        record["recordCount"] = NSNumber(value: manifest.recordCount)
        record["appVersion"] = manifest.appVersion as NSString

        do {
            try await database.save(record)
        } catch {
            throw MnemoError.backupFailed("CloudKit upload failed: \(error.localizedDescription)")
        }
    }

    public func fetchManifests() async throws -> [BackupManifest] {
        let query = CKQuery(
            recordType: Self.manifestRecordType,
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let (results, _) = try await database.records(matching: query)
            return try results.compactMap { _, result in
                guard case .success(let record) = result,
                      let manifestData = record["manifestData"] as? Data else {
                    return nil
                }
                return try JSONDecoder().decode(BackupManifest.self, from: manifestData)
            }
        } catch {
            throw MnemoError.backupFailed("CloudKit fetch failed: \(error.localizedDescription)")
        }
    }

    public func download(manifest: BackupManifest) async throws -> Data {
        let recordID = CKRecord.ID(recordName: manifest.id.uuidString)

        do {
            let record = try await database.record(for: recordID)
            guard let asset = record["payload"] as? CKAsset,
                  let fileURL = asset.fileURL else {
                throw MnemoError.restoreFailed("Backup payload not found in CloudKit")
            }
            return try Data(contentsOf: fileURL)
        } catch {
            throw MnemoError.restoreFailed("CloudKit download failed: \(error.localizedDescription)")
        }
    }

    public func delete(manifest: BackupManifest) async throws {
        let recordID = CKRecord.ID(recordName: manifest.id.uuidString)

        do {
            try await database.deleteRecord(withID: recordID)
        } catch {
            throw MnemoError.backupFailed("CloudKit delete failed: \(error.localizedDescription)")
        }
    }
}
