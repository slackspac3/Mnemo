import Foundation

public struct ThresholdUpdateEvent: Sendable {
    public let source: InputSource
    public let originalSummary: String
    public let correctedSummary: String
    public let semanticDelta: Double
    public let timestamp: Date

    public init(
        source: InputSource,
        originalSummary: String,
        correctedSummary: String,
        semanticDelta: Double,
        timestamp: Date = Date()
    ) {
        self.source = source
        self.originalSummary = originalSummary
        self.correctedSummary = correctedSummary
        self.semanticDelta = semanticDelta
        self.timestamp = timestamp
    }
}
