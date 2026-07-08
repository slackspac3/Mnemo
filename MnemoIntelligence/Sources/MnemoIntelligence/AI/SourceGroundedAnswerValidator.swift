import Foundation

public struct SourceGroundedAnswerOutput: Codable, Equatable, Sendable {
    public let answer: String
    public let sourceIdentifiers: [String]
    public let insufficientEvidence: Bool

    public init(
        answer: String,
        sourceIdentifiers: [String],
        insufficientEvidence: Bool
    ) {
        self.answer = answer
        self.sourceIdentifiers = sourceIdentifiers
        self.insufficientEvidence = insufficientEvidence
    }
}

public enum SourceGroundedAnswerParseError: Error, Equatable, Sendable {
    case invalidJSON
}

public struct SourceGroundedAnswerParser: Sendable {
    public init() {}

    public func parse(_ text: String) throws -> SourceGroundedAnswerOutput {
        guard let data = jsonObjectString(from: text).data(using: .utf8) else {
            throw SourceGroundedAnswerParseError.invalidJSON
        }

        do {
            return try JSONDecoder().decode(SourceGroundedAnswerOutput.self, from: data)
        } catch {
            throw SourceGroundedAnswerParseError.invalidJSON
        }
    }

    private func jsonObjectString(from text: String) -> String {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let start = cleaned.firstIndex(of: "{"),
            let end = cleaned.lastIndex(of: "}"),
            start <= end
        else {
            return cleaned
        }

        return String(cleaned[start...end])
    }
}

public struct SourceGroundedAnswerValidationResult: Equatable, Sendable {
    public let isValid: Bool
    public let shouldShowAnswer: Bool
    public let reason: String?

    public static let valid = SourceGroundedAnswerValidationResult(
        isValid: true,
        shouldShowAnswer: true,
        reason: nil
    )

    public static func invalid(_ reason: String) -> SourceGroundedAnswerValidationResult {
        SourceGroundedAnswerValidationResult(
            isValid: false,
            shouldShowAnswer: false,
            reason: reason
        )
    }
}

public struct SourceGroundedAnswerValidator: Sendable {
    public init() {}

    public func validate(
        _ output: SourceGroundedAnswerOutput,
        candidateSourceIdentifiers: Set<String>
    ) -> SourceGroundedAnswerValidationResult {
        let trimmedAnswer = output.answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.insufficientEvidence else {
            return .invalid("Model reported insufficient evidence.")
        }

        guard !trimmedAnswer.isEmpty else {
            return .invalid("Model returned an empty answer.")
        }

        guard !output.sourceIdentifiers.isEmpty else {
            return .invalid("Model returned no source identifiers.")
        }

        let malformedIdentifiers = output.sourceIdentifiers.filter { UUID(uuidString: $0) == nil }
        guard malformedIdentifiers.isEmpty else {
            return .invalid("Model returned malformed source identifiers.")
        }

        let cited = Set(output.sourceIdentifiers)
        guard cited.isSubset(of: candidateSourceIdentifiers) else {
            return .invalid("Model cited source identifiers outside the retrieval set.")
        }

        return .valid
    }
}
