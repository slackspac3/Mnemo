import Foundation

public struct SourceGroundedAnswerFidelityResult: Equatable, Sendable {
    public let isValid: Bool
    public let reason: String?

    public static let valid = SourceGroundedAnswerFidelityResult(
        isValid: true,
        reason: nil
    )

    public static func invalid(_ reason: String) -> SourceGroundedAnswerFidelityResult {
        SourceGroundedAnswerFidelityResult(
            isValid: false,
            reason: reason
        )
    }
}

public struct SourceGroundedAnswerFidelityValidator: Sendable {
    private let ignoredTokens: Set<String> = [
        "a", "an", "and", "are", "as", "at", "be", "because", "but", "by",
        "can", "choose", "did", "do", "does", "for", "from", "has", "have",
        "i", "if", "in", "is", "it", "its", "keep", "me", "my", "of", "on",
        "or", "recommended", "remember", "saved", "says", "should", "that",
        "the", "this", "to", "was", "were", "what", "when", "where", "which",
        "who", "with", "would", "you", "your"
    ]

    public init() {}

    public func validate(
        answer: String,
        question: String,
        sourceSummaries: [String]
    ) -> SourceGroundedAnswerFidelityResult {
        let answerTokens = significantTokens(in: answer)
        guard !answerTokens.isEmpty else {
            return .valid
        }

        let questionTokens = supportedTokens(in: question)
        let sourceTokens = supportedTokens(in: sourceSummaries.joined(separator: " "))
        let supported = questionTokens.union(sourceTokens)

        for token in answerTokens where !isSupported(token, by: supported) {
            return .invalid("Unsupported answer token: \(token)")
        }

        return .valid
    }

    private func significantTokens(in text: String) -> [String] {
        tokenise(text).filter { token in
            !ignoredTokens.contains(token)
        }
    }

    private func supportedTokens(in text: String) -> Set<String> {
        Set(tokenise(text))
    }

    private func isSupported(_ token: String, by supported: Set<String>) -> Bool {
        supported.contains(token)
            || supported.contains(singular(token))
            || supported.contains(plural(token))
            || supported.contains(possessiveBase(token))
    }

    private func tokenise(_ text: String) -> [String] {
        let folded = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()

        var tokens: [String] = []
        var current = ""

        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "-" {
                current.unicodeScalars.append(scalar)
            } else {
                appendToken(current, to: &tokens)
                current = ""
            }
        }
        appendToken(current, to: &tokens)

        return tokens
    }

    private func appendToken(_ rawToken: String, to tokens: inout [String]) {
        let token = rawToken.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        guard token.count > 1 else { return }
        tokens.append(token)
    }

    private func singular(_ token: String) -> String {
        guard token.count > 3, token.hasSuffix("s") else { return token }
        return String(token.dropLast())
    }

    private func plural(_ token: String) -> String {
        token + "s"
    }

    private func possessiveBase(_ token: String) -> String {
        guard token.hasSuffix("s") else { return token }
        return String(token.dropLast())
    }
}
