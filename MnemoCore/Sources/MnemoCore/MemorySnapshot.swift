import Foundation

public struct MemorySnapshot: Codable, Sendable, Identifiable {
    public let id: UUID
    public let summary: String
    public let memoryType: MemoryType
    public let persistenceScore: Double
    public let persistenceState: PersistenceState
    public let tags: [String]
    public let createdAt: Date
    public let processingTier: ProcessingTier
    public let threadId: UUID?
    public let corroboratingEvidenceIds: [UUID]

    public init(
        id: UUID = UUID(),
        summary: String,
        memoryType: MemoryType,
        persistenceScore: Double,
        persistenceState: PersistenceState,
        tags: [String] = [],
        createdAt: Date = Date(),
        processingTier: ProcessingTier,
        threadId: UUID? = nil,
        corroboratingEvidenceIds: [UUID] = []
    ) {
        self.id = id
        self.summary = summary
        self.memoryType = memoryType
        self.persistenceScore = persistenceScore
        self.persistenceState = persistenceState
        self.tags = tags
        self.createdAt = createdAt
        self.processingTier = processingTier
        self.threadId = threadId
        self.corroboratingEvidenceIds = corroboratingEvidenceIds
    }
}
