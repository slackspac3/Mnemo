import Foundation
import MnemoCore

/// Redacts selected obvious identifiers before a future cloud escalation path.
/// No cloud provider is configured in the current build.
public struct AnonymisationLayer: Sendable {

    public init() {}

    /// Redact email addresses, phone numbers, and URLs.
    /// This is a safeguard, not a complete anonymisation guarantee.
    public func anonymise(_ text: String) -> String {
        var result = text

        // Email addresses
        result = replacePattern(
            in: result,
            pattern: #"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"#,
            prefix: "EMAIL"
        )

        // Phone numbers (international and local formats)
        result = replacePattern(
            in: result,
            pattern: #"(\+?\d[\d\s\-().]{7,}\d)"#,
            prefix: "PHONE"
        )

        // URLs
        result = replacePattern(
            in: result,
            pattern: #"https?://[^\s]+"#,
            prefix: "URL"
        )

        return result
    }

    private func replacePattern(in text: String, pattern: String, prefix: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        var result = text
        let matches = regex.matches(in: text, range: range).reversed()
        for match in matches {
            if let swiftRange = Range(match.range, in: text) {
                let matched = String(text[swiftRange])
                let hash = abs(matched.hashValue) % 10000
                let replacement = "[\(prefix)_\(hash)]"
                result.replaceSubrange(swiftRange, with: replacement)
            }
        }
        return result
    }
}
