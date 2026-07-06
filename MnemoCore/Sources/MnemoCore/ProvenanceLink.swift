import Foundation

public struct ProvenanceLink: Codable, Sendable {
    public let id: UUID
    public let source: InputSource
    public let timestamp: Date
    public let extractionConfidence: Double
    public let processingTier: ProcessingTier
    public let modalityThresholdUsed: Double
    public let corroboratingEvidenceIds: [UUID]
    public let changeReason: String

    public init(
        id: UUID = UUID(),
        source: InputSource,
        timestamp: Date = Date(),
        extractionConfidence: Double,
        processingTier: ProcessingTier,
        modalityThresholdUsed: Double,
        corroboratingEvidenceIds: [UUID] = [],
        changeReason: String
    ) {
        self.id = id
        self.source = source
        self.timestamp = timestamp
        self.extractionConfidence = extractionConfidence
        self.processingTier = processingTier
        self.modalityThresholdUsed = modalityThresholdUsed
        self.corroboratingEvidenceIds = corroboratingEvidenceIds
        self.changeReason = changeReason
    }
}
