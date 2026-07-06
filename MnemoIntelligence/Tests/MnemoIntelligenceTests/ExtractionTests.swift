import Testing
import Foundation
@testable import MnemoIntelligence
import MnemoCore

@Suite("MnemoIntelligence — Extraction")
struct ExtractionTests {

    @Test("AnonymisationLayer removes email addresses")
    func anonymisesEmail() {
        let layer = AnonymisationLayer()
        let input = "Contact me at john.doe@example.com for details"
        let result = layer.anonymise(input)
        #expect(!result.contains("john.doe@example.com"))
        #expect(result.contains("[EMAIL_"))
    }

    @Test("AnonymisationLayer removes phone numbers")
    func anonymisesPhone() {
        let layer = AnonymisationLayer()
        let input = "Call me on +971 50 123 4567"
        let result = layer.anonymise(input)
        #expect(!result.contains("971 50 123 4567"))
    }

    @Test("AnonymisationLayer removes URLs")
    func anonymisesURL() {
        let layer = AnonymisationLayer()
        let input = "Check this out: https://example.com/private"
        let result = layer.anonymise(input)
        #expect(!result.contains("https://example.com/private"))
        #expect(result.contains("[URL_"))
    }

    @Test("ExtractionJSONParser parses valid JSON correctly")
    func parsesValidJSON() {
        let parser = ExtractionJSONParser()
        let json = """
        {
          "summary": "Clothing size medium at Zara",
          "memoryType": "preference",
          "persistenceScore": 0.85,
          "suggestedExpiryDays": null,
          "confidence": 0.92,
          "tags": ["clothing", "size", "zara"]
        }
        """
        let result = parser.parse(
            json: json,
            source: .text,
            processingTier: .onDevice,
            thresholdUsed: 0.90
        )
        #expect(result.summary == "Clothing size medium at Zara")
        #expect(result.memoryType == .preference)
        #expect(result.confidence == 0.92)
        #expect(result.tags.count == 3)
    }

    @Test("ExtractionJSONParser handles malformed JSON gracefully")
    func handlesMalformedJSON() {
        let parser = ExtractionJSONParser()
        let result = parser.parse(
            json: "not json at all",
            source: .voice,
            processingTier: .onDevice,
            thresholdUsed: 0.75
        )
        #expect(result.confidence < 0.5)
        #expect(result.memoryType == .fact)
    }

    @Test("ExtractionJSONParser strips markdown code fences")
    func stripsMarkdownFences() {
        let parser = ExtractionJSONParser()
        let json = """
        ```json
        {
          "summary": "Test memory",
          "memoryType": "fact",
          "persistenceScore": 0.5,
          "suggestedExpiryDays": null,
          "confidence": 0.8,
          "tags": ["test"]
        }
        ```
        """
        let result = parser.parse(
            json: json,
            source: .text,
            processingTier: .onDevice,
            thresholdUsed: 0.90
        )
        #expect(result.summary == "Test memory")
        #expect(result.confidence == 0.8)
    }

    @Test("ExtractionPromptBuilder includes raw text in prompt")
    func promptContainsInput() {
        let builder = ExtractionPromptBuilder()
        let prompt = builder.buildExtractionPrompt(
            rawText: "I wear medium at Zara",
            userContext: "clothing size"
        )
        #expect(prompt.contains("I wear medium at Zara"))
        #expect(prompt.contains("clothing size"))
    }

    @Test("CapabilityDetector returns a valid DeviceCapability")
    func capabilityDetectorReturnsResult() {
        let detector = CapabilityDetector()
        let capability = detector.detect()
        // On test hardware (Mac), Apple Intelligence may or may not be available.
        // We just verify the result is structurally valid.
        let validTiers: [DeviceTier] = [.full, .standard, .mlxOnly, .cloudPrimary, .unsupported]
        #expect(validTiers.contains(capability.tier))
    }

    @Test("ExtractionEngine returns a result for plain text input")
    func extractionEngineReturnsResult() async throws {
        let engine = ExtractionEngine()
        let result = try await engine.extract(
            rawText: "I always order a flat white at coffee shops",
            source: .text,
            threshold: 0.90,
            cloudPermitted: false
        )
        // With stub loaders returning nil, expect fallback result
        #expect(!result.summary.isEmpty)
        #expect(result.processingTier == .onDevice)
    }
}
