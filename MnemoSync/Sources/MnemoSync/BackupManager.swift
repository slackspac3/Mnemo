import Foundation
import MnemoCore
import MnemoMemory
import MnemoSecurity
import SwiftData
import CryptoKit

/// Orchestrates the full backup sequence.
/// Encryption uses a symmetric key stored by MnemoSecurity in the Keychain.
/// The key is never included in the backup payload.
public final class BackupManager: Sendable {

    public static let encryptionKeyIdentifier = "com.mnemo.backup.encryption.key"
    public static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    private let security: SecurityLayer
    private let cloudStore: CloudKitBackupStore

    public init(
        security: SecurityLayer = .shared,
        cloudStore: CloudKitBackupStore = CloudKitBackupStore()
    ) {
        self.security = security
        self.cloudStore = cloudStore
    }

    @MainActor
    public func backup(context: ModelContext) async throws -> BackupManifest {
        let memories = try snapshotMemories(context: context)
        let threads = try snapshotThreads(context: context)
        let userModelData = try snapshotUserModel(context: context)

        let encryptionKey = try getOrCreateEncryptionKey()

        let manifest = BackupManifest(
            appVersion: Self.appVersion,
            recordCount: memories.count,
            threadCount: threads.count,
            encryptionKeyIdentifier: Self.encryptionKeyIdentifier
        )

        let payload = BackupPayload(
            manifest: manifest,
            memories: memories,
            threads: threads,
            userModelData: userModelData
        )

        let payloadData = try JSONEncoder().encode(payload)
        let encryptedData = try encrypt(payloadData, using: encryptionKey)

        try await cloudStore.upload(
            manifest: manifest,
            encryptedPayload: encryptedData
        )

        return manifest
    }

    public func availableBackups() async throws -> [BackupManifest] {
        try await cloudStore.fetchManifests()
    }

    @MainActor
    private func snapshotMemories(context: ModelContext) throws -> [MemoryRecordSnapshot] {
        let descriptor = FetchDescriptor<MemoryRecord>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let records = try context.fetch(descriptor)
        return records.map { record in
            MemoryRecordSnapshot(
                id: record.id,
                rawInput: record.rawInput,
                summary: record.summary,
                memoryType: record.memoryType,
                persistenceScore: record.persistenceScore,
                persistenceState: record.persistenceState,
                inputSource: record.inputSource,
                processingTier: record.processingTier,
                modalityThresholdUsed: record.modalityThresholdUsed,
                confidence: record.confidence,
                tags: record.tags,
                corroboratingEvidenceIds: record.corroboratingEvidenceIds,
                provenanceChain: record.provenanceChain,
                isArchived: record.isArchived,
                isDone: record.isDone,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                owner: record.owner,
                visibility: record.visibility,
                threadId: record.threadId,
                subjectType: record.subjectType,
                subjectId: record.subjectId
            )
        }
    }

    @MainActor
    private func snapshotThreads(context: ModelContext) throws -> [MemoryThreadSnapshot] {
        let descriptor = FetchDescriptor<MemoryThread>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let threads = try context.fetch(descriptor)
        return threads.map { thread in
            MemoryThreadSnapshot(
                id: thread.id,
                name: thread.name,
                threadDescription: thread.threadDescription,
                startDate: thread.startDate,
                endDate: thread.endDate,
                isConfirmed: thread.isConfirmed,
                proposalConfidence: thread.proposalConfidence,
                createdAt: thread.createdAt,
                updatedAt: thread.updatedAt
            )
        }
    }

    @MainActor
    private func snapshotUserModel(context: ModelContext) throws -> Data {
        let descriptor = FetchDescriptor<UserModel>()
        guard let model = try context.fetch(descriptor).first else {
            return Data()
        }
        return model.modalityThresholdProfile
    }

    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let keyData = try? security.retrieveKey(identifier: Self.encryptionKeyIdentifier) {
            return SymmetricKey(data: keyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        try security.storeKey(keyData, identifier: Self.encryptionKeyIdentifier)
        return newKey
    }

    private func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw MnemoError.backupFailed("AES-GCM seal failed to produce combined data")
        }
        return combined
    }
}
