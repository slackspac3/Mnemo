import Foundation

public struct LocalAnswerComposerOutput: Codable, Equatable, Sendable {
    public let answer: String
    public let citedMemoryIds: [UUID]
    public let confidence: Double
    public let unsupportedClaims: [String]

    public init(
        answer: String,
        citedMemoryIds: [UUID],
        confidence: Double,
        unsupportedClaims: [String]
    ) {
        self.answer = answer
        self.citedMemoryIds = citedMemoryIds
        self.confidence = confidence
        self.unsupportedClaims = unsupportedClaims
    }
}

public enum LocalAnswerComposerError: Error, Equatable, Sendable {
    case invalidJSON
    case invalidConfidence(Double)
}

/// Parses the future local answer-composer JSON contract.
///
/// The model route is not wired yet; this parser makes the contract testable
/// before any model output is trusted by the UI.
public struct LocalAnswerComposer: Sendable {
    public init() {}

    public func parseOutput(json: String) throws -> LocalAnswerComposerOutput {
        guard let data = cleanedJSON(json).data(using: .utf8) else {
            throw LocalAnswerComposerError.invalidJSON
        }

        do {
            let output = try JSONDecoder().decode(LocalAnswerComposerOutput.self, from: data)
            guard (0...1).contains(output.confidence) else {
                throw LocalAnswerComposerError.invalidConfidence(output.confidence)
            }
            return output
        } catch let error as LocalAnswerComposerError {
            throw error
        } catch {
            throw LocalAnswerComposerError.invalidJSON
        }
    }

    private func cleanedJSON(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
