import Foundation
import MnemoCore
import MnemoMemory
import MnemoSecurity
import SwiftData
import CryptoKit

/// Handles restore from an encrypted CloudKit backup.
/// Decrypts the payload using the Secure Enclave-derived key,
/// then re-inserts all records into SwiftData.
public final class RestoreManager: Sendable {

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
    public func restore(
        from manifest: BackupManifest,
        into context: ModelContext
    ) async throws {
        let encryptedData = try await cloudStore.download(manifest: manifest)

        let keyData = try security.retrieveKey(
            identifier: manifest.encryptionKeyIdentifier
        )
        let key = SymmetricKey(data: keyData)

        let decryptedData = try decrypt(encryptedData, using: key)
        let payload = try JSONDecoder().decode(BackupPayload.self, from: decryptedData)

        try context.delete(model: MemoryRecord.self)
        try context.delete(model: MemoryThread.self)
        try context.save()

        for snapshot in payload.memories {
            let record = MemoryRecord(
                id: snapshot.id,
                rawInput: snapshot.rawInput,
                summary: snapshot.summary,
                memoryType: MemoryType(rawValue: snapshot.memoryType) ?? .fact,
                persistenceScore: snapshot.persistenceScore,
                persistenceState: PersistenceState(rawValue: snapshot.persistenceState) ?? .active,
                inputSource: InputSource(rawValue: snapshot.inputSource) ?? .text,
                processingTier: ProcessingTier(rawValue: snapshot.processingTier) ?? .onDevice,
                modalityThresholdUsed: snapshot.modalityThresholdUsed,
                confidence: snapshot.confidence,
                tags: snapshot.tags,
                corroboratingEvidenceIds: snapshot.corroboratingEvidenceIds,
                provenanceChain: snapshot.provenanceChain,
                isArchived: snapshot.isArchived,
                isDone: snapshot.isDone,
                createdAt: snapshot.createdAt,
                updatedAt: snapshot.updatedAt,
                owner: snapshot.owner,
                visibility: snapshot.visibility,
                threadId: snapshot.threadId,
                subjectType: snapshot.subjectType,
                subjectId: snapshot.subjectId
            )
            context.insert(record)
        }

        for snapshot in payload.threads {
            let thread = MemoryThread(
                id: snapshot.id,
                name: snapshot.name,
                threadDescription: snapshot.threadDescription,
                startDate: snapshot.startDate,
                endDate: snapshot.endDate,
                isConfirmed: snapshot.isConfirmed,
                proposalConfidence: snapshot.proposalConfidence,
                createdAt: snapshot.createdAt,
                updatedAt: snapshot.updatedAt
            )
            context.insert(thread)
        }

        try context.save()
    }

    private func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
