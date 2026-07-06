import Foundation
import MnemoCore

/// Builds structured extraction prompts for the LLM.
/// The prompt is designed to produce reliable JSON output from small on-device models.
/// Structured output format is strict — the JSON parser expects this exact schema.
public struct ExtractionPromptBuilder: Sendable {

    public init() {}

    public func buildExtractionPrompt(rawText: String, userContext: String?) -> String {
        let contextLine = userContext.map { "User context: \($0)" } ?? "User context: none"

        return """
        You are a memory extraction assistant for personal information management.
        Extract structured information from the input below.
        Return ONLY valid JSON. No preamble. No explanation. No markdown.

        Input: \(rawText)
        \(contextLine)

        Return JSON matching this exact schema:
        {
          "summary": "concise human-readable summary of what to remember",
          "memoryType": "preference|list|credential|event|fact|instruction|intention",
          "persistenceScore": 0.0,
          "suggestedExpiryDays": null,
          "confidence": 0.0,
          "tags": []
        }

        Rules:
        - summary: one sentence, plain English, what the user should remember
        - memoryType: exactly one of the enum values shown
        - persistenceScore: 0.0 to 1.0. Preferences/credentials = 0.8+. Lists/events = 0.5. Sessions = 0.2
        - suggestedExpiryDays: integer days until expiry, or null for persistent memories
        - confidence: your confidence in the extraction, 0.0 to 1.0
        - tags: array of 1-3 short lowercase strings categorising the memory
        """
    }

    public func buildRecallPrompt(query: String, memorySummaries: [String]) -> String {
        let memoriesText = memorySummaries.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        return """
        You are a personal memory assistant. Answer the user's question using only
        the memories provided. Be concise and direct. If the answer is not in the
        memories, say "I don't have that information saved."

        User's memories:
        \(memoriesText)

        Question: \(query)

        Answer in 1-3 sentences maximum.
        """
    }
}
