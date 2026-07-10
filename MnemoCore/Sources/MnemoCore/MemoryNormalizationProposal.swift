import Foundation

public struct MemoryCorrection: Codable, Equatable, Identifiable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case capitalization
        case spelling
        case punctuation
        case sourcePreservation
        case ambiguous
    }

    public let original: String
    public let replacement: String
    public let kind: Kind
    public let confidence: Double
    public let reason: String

    public var id: String {
        "\(kind.rawValue):\(original):\(replacement)"
    }

    public init(
        original: String,
        replacement: String,
        kind: Kind,
        confidence: Double,
        reason: String
    ) {
        self.original = original
        self.replacement = replacement
        self.kind = kind
        self.confidence = max(0.0, min(1.0, confidence))
        self.reason = reason
    }
}

public struct MemoryNormalizationProposal: Codable, Equatable, Sendable {
    public let originalSummary: String
    public let proposedSummary: String
    public let corrections: [MemoryCorrection]
    public let requiresClarification: Bool
    public let clarificationQuestion: String?

    public var hasChanges: Bool {
        originalSummary != proposedSummary
    }

    public init(
        originalSummary: String,
        proposedSummary: String,
        corrections: [MemoryCorrection] = [],
        requiresClarification: Bool = false,
        clarificationQuestion: String? = nil
    ) {
        self.originalSummary = originalSummary
        self.proposedSummary = proposedSummary
        self.corrections = corrections
        self.requiresClarification = requiresClarification
        self.clarificationQuestion = clarificationQuestion
    }
}
