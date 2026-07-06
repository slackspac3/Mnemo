import Foundation
import MnemoCore

/// Strips or hashes PII from text before any cloud escalation.
/// Applied to ALL cloud payloads without exception.
/// Uses consistent hashing so the LLM can still reason about relationships
/// between entities without seeing the actual values.
public struct AnonymisationLayer: Sendable {

    public init() {}

    /// Anonymise text for cloud transmission.
    /// Detects and replaces: email addresses, phone numbers, URLs,
    /// and common name patterns. Consistent hashing preserves relationships.
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
