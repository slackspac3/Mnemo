import Foundation
import SwiftData
import MnemoCore

/// Primary memory object. Every capture becomes a MemoryRecord.
/// Enums stored as String rawValues for forward schema compatibility.
/// ProvenanceChain stored as Data (JSON-encoded [ProvenanceLink]) — append-only.
@Model
public final class MemoryRecord {
    @Attribute(.unique) public var id: UUID
    public var rawInput: String
    public var summary: String
    public var memoryType: String            // MemoryType.rawValue
    public var persistenceScore: Double      // 0.0 to 1.0
    public var persistenceState: String      // PersistenceState.rawValue
    public var inputSource: String           // InputSource.rawValue
    public var processingTier: String        // ProcessingTier.rawValue
    public var modalityThresholdUsed: Double
    public var confidence: Double
    public var tags: [String]
    public var corroboratingEvidenceIds: [UUID]
    public var provenanceChain: Data         // JSON: [ProvenanceLink] — append-only
    public var isArchived: Bool
    public var isDone: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var owner: String                 // 'local' in v1
    public var visibility: String            // 'private' in v1
    public var threadId: UUID?
    public var subjectType: String           // 'self' | 'person'
    public var subjectId: UUID?              // PersonSubject.id if subjectType == 'person'

    public init(
        id: UUID = UUID(),
        rawInput: String,
        summary: String,
        memoryType: MemoryType,
        persistenceScore: Double = 0.5,
        persistenceState: PersistenceState = .active,
        inputSource: InputSource,
        processingTier: ProcessingTier,
        modalityThresholdUsed: Double,
        confidence: Double,
        tags: [String] = [],
        corroboratingEvidenceIds: [UUID] = [],
        provenanceChain: Data = Data(),
        isArchived: Bool = false,
        isDone: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        owner: String = "local",
        visibility: String = "private",
        threadId: UUID? = nil,
        subjectType: String = "self",
        subjectId: UUID? = nil
    ) {
        self.id = id
        self.rawInput = rawInput
        self.summary = summary
        self.memoryType = memoryType.rawValue
        self.persistenceScore = persistenceScore
        self.persistenceState = persistenceState.rawValue
        self.inputSource = inputSource.rawValue
        self.processingTier = processingTier.rawValue
        self.modalityThresholdUsed = modalityThresholdUsed
        self.confidence = confidence
        self.tags = tags
        self.corroboratingEvidenceIds = corroboratingEvidenceIds
        self.provenanceChain = provenanceChain
        self.isArchived = isArchived
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.owner = owner
        self.visibility = visibility
        self.threadId = threadId
        self.subjectType = subjectType
        self.subjectId = subjectId
    }

    // MARK: - Typed accessors

    public var memoryTypeEnum: MemoryType? { MemoryType(rawValue: memoryType) }
    public var persistenceStateEnum: PersistenceState? { PersistenceState(rawValue: persistenceState) }
    public var inputSourceEnum: InputSource? { InputSource(rawValue: inputSource) }
    public var processingTierEnum: ProcessingTier? { ProcessingTier(rawValue: processingTier) }

    public func toSnapshot() -> MemorySnapshot {
        MemorySnapshot(
            id: id,
            summary: summary,
            memoryType: memoryTypeEnum ?? .fact,
            persistenceScore: persistenceScore,
            persistenceState: persistenceStateEnum ?? .active,
            tags: tags,
            createdAt: createdAt,
            processingTier: processingTierEnum ?? .onDevice,
            threadId: threadId,
            corroboratingEvidenceIds: corroboratingEvidenceIds
        )
    }
}
