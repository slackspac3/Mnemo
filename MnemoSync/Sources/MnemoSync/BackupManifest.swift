import Foundation
import MnemoCore

/// Metadata record for a Mnemo backup archive.
/// Stored alongside the encrypted backup in CloudKit.
/// The encryption key reference points to the Secure Enclave key -
/// it is never included in the backup payload itself.
public struct BackupManifest: Codable, Sendable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public let appVersion: String
    public let recordCount: Int
    public let threadCount: Int
    public let encryptionKeyIdentifier: String
    public let schemaVersion: Int

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        appVersion: String,
        recordCount: Int,
        threadCount: Int,
        encryptionKeyIdentifier: String,
        schemaVersion: Int = 1
    ) {
        self.id = id
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.recordCount = recordCount
        self.threadCount = threadCount
        self.encryptionKeyIdentifier = encryptionKeyIdentifier
        self.schemaVersion = schemaVersion
    }
}

/// Serialisable snapshot of a MemoryRecord for backup purposes.
/// Uses raw string values for all enums for forward compatibility.
public struct MemoryRecordSnapshot: Codable, Sendable {
    public let id: UUID
    public let rawInput: String
    public let summary: String
    public let memoryType: String
    public let persistenceScore: Double
    public let persistenceState: String
    public let inputSource: String
    public let processingTier: String
    public let modalityThresholdUsed: Double
    public let confidence: Double
    public let tags: [String]
    public let corroboratingEvidenceIds: [UUID]
    public let provenanceChain: Data
    public let isArchived: Bool
    public let isDone: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let owner: String
    public let visibility: String
    public let threadId: UUID?
    public let subjectType: String
    public let subjectId: UUID?
}

/// Serialisable snapshot of a MemoryThread for backup purposes.
public struct MemoryThreadSnapshot: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let threadDescription: String
    public let startDate: Date
    public let endDate: Date?
    public let isConfirmed: Bool
    public let proposalConfidence: Double
    public let createdAt: Date
    public let updatedAt: Date
}

/// Complete backup payload, encrypted before transmission.
public struct BackupPayload: Codable, Sendable {
    public let manifest: BackupManifest
    public let memories: [MemoryRecordSnapshot]
    public let threads: [MemoryThreadSnapshot]
    public let userModelData: Data
}
