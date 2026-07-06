import Foundation

public struct ExtractionResult: Sendable {
    public let summary: String
    public let memoryType: MemoryType
    public let persistenceScore: Double
    public let suggestedExpiry: Date?
    public let confidence: Double
    public let processingTier: ProcessingTier
    public let modalityThresholdUsed: Double
    public let tags: [String]

    public init(
        summary: String,
        memoryType: MemoryType,
        persistenceScore: Double,
        suggestedExpiry: Date? = nil,
        confidence: Double,
        processingTier: ProcessingTier,
        modalityThresholdUsed: Double,
        tags: [String] = []
    ) {
        self.summary = summary
        self.memoryType = memoryType
        self.persistenceScore = persistenceScore
        self.suggestedExpiry = suggestedExpiry
        self.confidence = confidence
        self.processingTier = processingTier
        self.modalityThresholdUsed = modalityThresholdUsed
        self.tags = tags
    }
}
