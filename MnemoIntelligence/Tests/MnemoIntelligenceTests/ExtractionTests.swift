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

    @Test("Normalizer preserves distinctive casing from the original capture")
    func normalizerPreservesSourceCasing() async {
        let normalizer = MemoryTextNormalizer(generator: { _, _ in nil })
        let result = await normalizer.normalize(
            rawInput: "I loved the waterfall in Guam",
            extractionResult: extraction(summary: "Loved the waterfall in guam")
        )

        #expect(result.summary == "I loved the waterfall in Guam")
        #expect(result.normalizationProposal?.hasChanges == false)
    }

    @Test("Normalizer preserves a concise sentence while correcting its proper noun")
    func normalizerDoesNotDropSentenceSubject() async {
        let json = normalizationJSON(
            original: "I loved the waterfall in guam",
            proposed: "I loved the waterfall in Guam",
            kind: "capitalization",
            correctionOriginal: "guam",
            correctionReplacement: "Guam"
        )
        let normalizer = MemoryTextNormalizer(generator: { _, _ in json })
        let result = await normalizer.normalize(
            rawInput: "I loved the waterfall in guam",
            extractionResult: extraction(summary: "loved the waterfall in guam")
        )

        #expect(result.summary == "I loved the waterfall in Guam")
        #expect(result.normalizationProposal?.originalSummary == "I loved the waterfall in guam")
        #expect(result.normalizationProposal?.corrections.contains {
            $0.original == "guam" && $0.replacement == "Guam"
        } == true)
    }

    @Test("Normalizer proposes sentence capitalization without a model")
    func normalizerCapitalizesSentence() async {
        let normalizer = MemoryTextNormalizer(generator: { _, _ in nil })
        let result = await normalizer.normalize(
            rawInput: "loved the waterfall",
            extractionResult: extraction(summary: "loved the waterfall")
        )

        #expect(result.summary == "Loved the waterfall")
        #expect(result.normalizationProposal?.hasChanges == true)
    }

    @Test(
        "Normalizer covers common proper-name categories",
        arguments: [
            EntityFixture(raw: "meet aoife murphy", proposed: "Meet Aoife Murphy", kind: "capitalization"),
            EntityFixture(raw: "waterfall in guam", proposed: "Waterfall in Guam", kind: "capitalization"),
            EntityFixture(raw: "dinner in al barsha", proposed: "Dinner in Al Barsha", kind: "capitalization"),
            EntityFixture(raw: "visit são paulo", proposed: "Visit São Paulo", kind: "capitalization"),
            EntityFixture(raw: "dinner at nobu dubai", proposed: "Dinner at Nobu Dubai", kind: "capitalization"),
            EntityFixture(raw: "lunch at mcdonalds", proposed: "Lunch at McDonald's", kind: "punctuation"),
            EntityFixture(raw: "buy an iphone from apple", proposed: "Buy an iPhone from Apple", kind: "capitalization"),
            EntityFixture(raw: "watch it on youtube", proposed: "Watch it on YouTube", kind: "capitalization"),
            EntityFixture(raw: "ask openai tomorrow", proposed: "Ask OpenAI tomorrow", kind: "capitalization"),
            EntityFixture(raw: "meeting at new york university", proposed: "Meeting at New York University", kind: "capitalization"),
            EntityFixture(raw: "stay at burj al arab", proposed: "Stay at Burj Al Arab", kind: "capitalization"),
            EntityFixture(raw: "fly emirates from dxb to the uae", proposed: "Fly Emirates from DXB to the UAE", kind: "capitalization")
        ]
    )
    func normalizerHandlesEntityCategory(fixture: EntityFixture) async {
        let json = normalizationJSON(
            original: fixture.raw,
            proposed: fixture.proposed,
            kind: fixture.kind
        )
        let normalizer = MemoryTextNormalizer(generator: { _, _ in json })
        let result = await normalizer.normalize(
            rawInput: fixture.raw,
            extractionResult: extraction(summary: fixture.raw)
        )

        #expect(result.summary == fixture.proposed)
        #expect(result.normalizationProposal?.hasChanges == true)
        #expect(result.normalizationProposal?.corrections.isEmpty == false)
    }

    @Test(
        "Normalizer rejects changes to protected factual values",
        arguments: [
            ProtectedFixture(original: "Flight EK202 leaves at 08:30", proposed: "Flight EK203 leaves at 08:30"),
            ProtectedFixture(original: "Paid AED 1,250.50", proposed: "Paid AED 1,520.50"),
            ProtectedFixture(original: "Email sam@example.com", proposed: "Email sara@example.com"),
            ProtectedFixture(original: "Open https://example.com/a", proposed: "Open https://example.com/b"),
            ProtectedFixture(original: "Message @sam_91", proposed: "Message @sam_92"),
            ProtectedFixture(original: "Buy iPhone 17 Pro", proposed: "Buy iPhone 18 Pro"),
            ProtectedFixture(original: "Appointment 10/07/2026", proposed: "Appointment 11/07/2026")
        ]
    )
    func normalizerProtectsFacts(fixture: ProtectedFixture) async {
        let json = normalizationJSON(
            original: fixture.original,
            proposed: fixture.proposed,
            kind: "spelling"
        )
        let normalizer = MemoryTextNormalizer(generator: { _, _ in json })
        let result = await normalizer.normalize(
            rawInput: fixture.original,
            extractionResult: extraction(summary: fixture.original)
        )

        #expect(result.summary != fixture.proposed)
        #expect(result.summary.contains(fixture.original.split(separator: " ").last.map(String.init) ?? ""))
    }

    @Test("Normalizer rejects changes to negation or meaning")
    func normalizerProtectsMeaning() {
        #expect(!MemoryTextNormalizer.isFaithful(
            original: "Do not order shellfish",
            proposed: "Order shellfish"
        ))
        #expect(!MemoryTextNormalizer.isFaithful(
            original: "Meet Ana at the clinic",
            proposed: "Cancel the appointment and call Ana next week"
        ))
        #expect(!MemoryTextNormalizer.isFaithful(
            original: "Loved the waterfall in Guam",
            proposed: "Loved the waterfall in guam"
        ))
    }

    @Test("Normalizer surfaces ambiguous entity questions without guessing")
    func normalizerSurfacesAmbiguity() async {
        let json = normalizationJSON(
            original: "meet jordan on friday",
            proposed: "Meet jordan on friday",
            kind: "ambiguous",
            clarification: "Is Jordan a person or a place?"
        )
        let normalizer = MemoryTextNormalizer(generator: { _, _ in json })
        let result = await normalizer.normalize(
            rawInput: "meet jordan on friday",
            extractionResult: extraction(summary: "meet jordan on friday")
        )

        #expect(result.normalizationProposal?.requiresClarification == true)
        #expect(result.normalizationProposal?.clarificationQuestion == "Is Jordan a person or a place?")
    }
}

struct EntityFixture: Sendable, CustomTestStringConvertible {
    let raw: String
    let proposed: String
    let kind: String

    var testDescription: String { "\(raw) -> \(proposed)" }
}

struct ProtectedFixture: Sendable, CustomTestStringConvertible {
    let original: String
    let proposed: String

    var testDescription: String { "\(original) != \(proposed)" }
}

private func extraction(summary: String) -> ExtractionResult {
    ExtractionResult(
        summary: summary,
        memoryType: .fact,
        persistenceScore: 0.5,
        confidence: 0.8,
        processingTier: .onDevice,
        modalityThresholdUsed: 0.9
    )
}

private func normalizationJSON(
    original: String,
    proposed: String,
    kind: String,
    clarification: String? = nil,
    correctionOriginal: String? = nil,
    correctionReplacement: String? = nil
) -> String {
    let payload: [String: Any] = [
        "proposedSummary": proposed,
        "corrections": original == proposed ? [] : [[
            "original": correctionOriginal ?? original,
            "replacement": correctionReplacement ?? proposed,
            "kind": kind,
            "confidence": 0.95,
            "reason": "Recognized name or corrected spelling"
        ]],
        "requiresClarification": clarification != nil,
        "clarificationQuestion": clarification ?? NSNull()
    ]
    let data = try! JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
    return String(decoding: data, as: UTF8.self)
}
