import Foundation

public struct AnswerCitationValidationResult: Equatable, Sendable {
    public let isValid: Bool
    public let reason: String?

    public static let valid = AnswerCitationValidationResult(isValid: true, reason: nil)

    public static func invalid(_ reason: String) -> AnswerCitationValidationResult {
        AnswerCitationValidationResult(isValid: false, reason: reason)
    }
}

/// Validates the source-grounding contract before any local model answer can
/// become user-visible.
public struct AnswerCitationValidator: Sendable {
    public init() {}

    public func validate(
        _ output: LocalAnswerComposerOutput,
        candidateMemoryIds: Set<UUID>
    ) -> AnswerCitationValidationResult {
        if !output.unsupportedClaims.isEmpty {
            return .invalid("Model reported unsupported claims.")
        }

        let citedIds = Set(output.citedMemoryIds)
        let unknownIds = citedIds.subtracting(candidateMemoryIds)
        if !unknownIds.isEmpty {
            return .invalid("Model cited memory IDs outside the retrieval set.")
        }

        if citedIds.isEmpty && !isCautiousNoMatch(output.answer) {
            return .invalid("Answer has no citations and is not a cautious no-match.")
        }

        return .valid
    }

    private func isCautiousNoMatch(_ answer: String) -> Bool {
        let lowercased = answer.lowercased()
        return lowercased.contains("do not have") ||
            lowercased.contains("could not find") ||
            lowercased.contains("not saved") ||
            lowercased.contains("no saved memory")
    }
}
