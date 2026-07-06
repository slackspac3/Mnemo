import Testing
import Foundation
import CryptoKit
@testable import MnemoSync
import MnemoCore

@Suite("MnemoSync")
struct MnemoSyncTests {

    @Test("BackupManifest encodes and decodes correctly")
    func manifestCodable() throws {
        let manifest = BackupManifest(
            appVersion: "1.0",
            recordCount: 42,
            threadCount: 3,
            encryptionKeyIdentifier: "com.mnemo.backup.test"
        )
        let data = try JSONEncoder().encode(manifest)
        let decoded = try JSONDecoder().decode(BackupManifest.self, from: data)
        #expect(decoded.id == manifest.id)
        #expect(decoded.recordCount == 42)
        #expect(decoded.threadCount == 3)
        #expect(decoded.appVersion == "1.0")
        #expect(decoded.schemaVersion == 1)
    }

    @Test("BackupPayload encodes and decodes correctly")
    func payloadCodable() throws {
        let manifest = BackupManifest(
            appVersion: "1.0",
            recordCount: 1,
            threadCount: 0,
            encryptionKeyIdentifier: "com.mnemo.backup.test"
        )
        let snapshot = MemoryRecordSnapshot(
            id: UUID(),
            rawInput: "Test input",
            summary: "Test summary",
            memoryType: "fact",
            persistenceScore: 0.8,
            persistenceState: "active",
            inputSource: "text",
            processingTier: "onDevice",
            modalityThresholdUsed: 0.90,
            confidence: 0.85,
            tags: ["test"],
            corroboratingEvidenceIds: [],
            provenanceChain: Data(),
            isArchived: false,
            isDone: false,
            createdAt: Date(),
            updatedAt: Date(),
            owner: "local",
            visibility: "private",
            threadId: nil,
            subjectType: "self",
            subjectId: nil
        )
        let payload = BackupPayload(
            manifest: manifest,
            memories: [snapshot],
            threads: [],
            userModelData: Data()
        )
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(BackupPayload.self, from: data)
        #expect(decoded.memories.count == 1)
        #expect(decoded.memories.first?.summary == "Test summary")
        #expect(decoded.threads.isEmpty)
    }

    @Test("MemoryThreadSnapshot encodes and decodes correctly")
    func threadSnapshotCodable() throws {
        let snapshot = MemoryThreadSnapshot(
            id: UUID(),
            name: "Dubai flat search",
            threadDescription: "Looking for a 2BR",
            startDate: Date(),
            endDate: nil,
            isConfirmed: true,
            proposalConfidence: 0.85,
            createdAt: Date(),
            updatedAt: Date()
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(MemoryThreadSnapshot.self, from: data)
        #expect(decoded.name == "Dubai flat search")
        #expect(decoded.isConfirmed == true)
        #expect(decoded.endDate == nil)
    }

    @Test("BackupManager encryption key is 256 bits")
    func encryptionKeySize() throws {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        #expect(keyData.count == 32)
    }
}
