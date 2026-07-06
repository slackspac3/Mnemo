import Foundation
import MnemoCore

/// Parses LLM JSON output into ExtractionResult.
/// Handles malformed JSON gracefully — always returns a result,
/// with low confidence if parsing fails.
public struct ExtractionJSONParser: Sendable {

    public init() {}

    private struct RawExtractionResponse: Decodable {
        let summary: String
        let memoryType: String
        let persistenceScore: Double
        let suggestedExpiryDays: Int?
        let confidence: Double
        let tags: [String]
    }

    public func parse(
        json: String,
        source: InputSource,
        processingTier: ProcessingTier,
        thresholdUsed: Double
    ) -> ExtractionResult {
        let cleanedJSON = cleanJSON(json)

        guard
            let data = cleanedJSON.data(using: .utf8),
            let raw = try? JSONDecoder().decode(RawExtractionResponse.self, from: data)
        else {
            // Graceful fallback — return low-confidence fact
            return ExtractionResult(
                summary: cleanedJSON.isEmpty ? "Captured note" : String(cleanedJSON.prefix(200)),
                memoryType: .fact,
                persistenceScore: 0.3,
                confidence: 0.1,
                processingTier: processingTier,
                modalityThresholdUsed: thresholdUsed,
                tags: ["unprocessed"]
            )
        }

        let memoryType = MemoryType(rawValue: raw.memoryType) ?? .fact
        let suggestedExpiry: Date? = raw.suggestedExpiryDays.map {
            Calendar.current.date(byAdding: .day, value: $0, to: Date())!
        }

        return ExtractionResult(
            summary: raw.summary,
            memoryType: memoryType,
            persistenceScore: max(0.0, min(1.0, raw.persistenceScore)),
            suggestedExpiry: suggestedExpiry,
            confidence: max(0.0, min(1.0, raw.confidence)),
            processingTier: processingTier,
            modalityThresholdUsed: thresholdUsed,
            tags: raw.tags
        )
    }

    /// Strip markdown code fences and leading/trailing whitespace.
    private func cleanJSON(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
