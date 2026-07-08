import Testing
import Foundation
@testable import MnemoIntelligence
import MnemoCore
import MnemoMemory

@Suite("MnemoIntelligence — AI Core")
struct AICoreTests {

    @Test("AI Core flags default off for TestFlight")
    func aiCoreFlagsDefaultOff() {
        let flags = AICoreFlags.testFlightDefault

        #expect(flags.aiCoreEnabled == false)
        #expect(flags.mlxEmbeddingsEnabled == false)
        #expect(flags.mlxAnswerComposerEnabled == false)
        #expect(flags.foundationModelsEnabled == false)
        #expect(flags.deterministicRecallFallbackEnabled == true)
        #expect(flags.hasModelBackedPathEnabled == false)
    }

    @Test("Capability detector does not report MLX without assets")
    func capabilityDetectorDoesNotReportMLXWithoutAssets() {
        let capability = CapabilityDetector().detect()

        #expect(capability.mnemoOnDeviceAvailable == false)
    }

    @Test("MLX loader fails closed without bundled assets")
    func mlxLoaderFailsClosedWithoutAssets() async throws {
        let loader = MLXModelLoader()

        try await loader.load()

        #expect(await loader.isReady == false)
        if case let .failed(reason) = await loader.state {
            #expect(reason.localizedCaseInsensitiveContains("not bundled"))
        } else {
            Issue.record("Expected MLX loader to fail closed without model assets.")
        }
    }

    @Test("Foundation Models loader stays unavailable until wired")
    func foundationModelsLoaderStaysUnavailableUntilWired() async {
        let loader = FoundationModelLoader()

        await loader.load()

        #expect(await loader.isAvailable == false)
        if case let .unavailable(reason) = await loader.state {
            #expect(reason.localizedCaseInsensitiveContains("not wired"))
        } else {
            Issue.record("Expected Foundation Models loader to remain unavailable.")
        }
    }

    @Test("AI recall pipeline falls back when disabled")
    @MainActor
    func aiRecallPipelineFallsBackWhenDisabled() async {
        let memory = Self.makeMemory("Mum wears size 38 shoes.")
        let pipeline = AIRecallPipeline(flags: .testFlightDefault)

        let result = await pipeline.recall(
            query: "What size does mum wear?",
            memories: [memory]
        )

        #expect(result.citedMemoryIds == [memory.id])
        #expect(result.text.localizedCaseInsensitiveContains("38"))
    }

    @Test("AI recall pipeline keeps deterministic fallback even when prototype flags are on")
    @MainActor
    func aiRecallPipelineFallsBackWhenPrototypeEnabled() async {
        let memory = Self.makeMemory("The spare car key is in the black pouch.")
        let pipeline = AIRecallPipeline(flags: .debugPrototype)

        let result = await pipeline.recall(
            query: "Where is the spare car key?",
            memories: [memory]
        )

        #expect(result.citedMemoryIds == [memory.id])
        #expect(result.text.localizedCaseInsensitiveContains("black pouch"))
    }

    @Test("Local answer composer parses valid JSON")
    func localAnswerComposerParsesJSON() throws {
        let id = UUID()
        let json = """
        {
          "answer": "Mum wears size 38 shoes.",
          "citedMemoryIds": ["\(id.uuidString)"],
          "confidence": 0.92,
          "unsupportedClaims": []
        }
        """

        let output = try LocalAnswerComposer().parseOutput(json: json)

        #expect(output.answer == "Mum wears size 38 shoes.")
        #expect(output.citedMemoryIds == [id])
        #expect(output.confidence == 0.92)
        #expect(output.unsupportedClaims.isEmpty)
    }

    @Test("Local answer composer rejects malformed JSON")
    func localAnswerComposerRejectsMalformedJSON() {
        #expect(throws: LocalAnswerComposerError.invalidJSON) {
            _ = try LocalAnswerComposer().parseOutput(json: "not json")
        }
    }

    @Test("Local answer composer rejects invalid confidence")
    func localAnswerComposerRejectsInvalidConfidence() {
        let json = """
        {
          "answer": "Answer",
          "citedMemoryIds": [],
          "confidence": 1.4,
          "unsupportedClaims": []
        }
        """

        #expect(throws: LocalAnswerComposerError.invalidConfidence(1.4)) {
            _ = try LocalAnswerComposer().parseOutput(json: json)
        }
    }

    @Test("Citation validator rejects unsupported IDs")
    func citationValidatorRejectsUnsupportedIDs() {
        let cited = UUID()
        let candidate = UUID()
        let output = LocalAnswerComposerOutput(
            answer: "Mum wears size 38 shoes.",
            citedMemoryIds: [cited],
            confidence: 0.9,
            unsupportedClaims: []
        )

        let result = AnswerCitationValidator().validate(
            output,
            candidateMemoryIds: [candidate]
        )

        #expect(result.isValid == false)
        #expect(result.reason?.localizedCaseInsensitiveContains("outside the retrieval set") == true)
    }

    @Test("Citation validator rejects uncited factual answers")
    func citationValidatorRejectsUncitedAnswers() {
        let output = LocalAnswerComposerOutput(
            answer: "Mum wears size 38 shoes.",
            citedMemoryIds: [],
            confidence: 0.9,
            unsupportedClaims: []
        )

        let result = AnswerCitationValidator().validate(
            output,
            candidateMemoryIds: []
        )

        #expect(result.isValid == false)
        #expect(result.reason?.localizedCaseInsensitiveContains("no citations") == true)
    }

    @Test("Citation validator allows cautious no-match without citations")
    func citationValidatorAllowsCautiousNoMatch() {
        let output = LocalAnswerComposerOutput(
            answer: "I do not have Ahmed's birthday saved.",
            citedMemoryIds: [],
            confidence: 0.86,
            unsupportedClaims: []
        )

        let result = AnswerCitationValidator().validate(
            output,
            candidateMemoryIds: []
        )

        #expect(result.isValid == true)
    }

    @Test("Citation validator rejects model-reported unsupported claims")
    func citationValidatorRejectsUnsupportedClaims() {
        let id = UUID()
        let output = LocalAnswerComposerOutput(
            answer: "The passport number is 1234.",
            citedMemoryIds: [id],
            confidence: 0.4,
            unsupportedClaims: ["passport number is not in source"]
        )

        let result = AnswerCitationValidator().validate(
            output,
            candidateMemoryIds: [id]
        )

        #expect(result.isValid == false)
        #expect(result.reason?.localizedCaseInsensitiveContains("unsupported claims") == true)
    }

    @Test("Source-grounded answer parser accepts JSON inside text")
    func sourceGroundedAnswerParserAcceptsJSONInsideText() throws {
        let id = UUID()
        let text = """
        Result:
        ```json
        {
          "answer": "The waterfall you loved was in Guam.",
          "sourceIdentifiers": ["\(id.uuidString)"],
          "insufficientEvidence": false
        }
        ```
        """

        let output = try SourceGroundedAnswerParser().parse(text)

        #expect(output.answer == "The waterfall you loved was in Guam.")
        #expect(output.sourceIdentifiers == [id.uuidString])
        #expect(output.insufficientEvidence == false)
    }

    @Test("Source-grounded validator accepts matching source ID")
    func sourceGroundedValidatorAcceptsMatchingSourceID() {
        let id = UUID().uuidString
        let output = SourceGroundedAnswerOutput(
            answer: "The waterfall you loved was in Guam.",
            sourceIdentifiers: [id],
            insufficientEvidence: false
        )

        let result = SourceGroundedAnswerValidator().validate(
            output,
            candidateSourceIdentifiers: [id]
        )

        #expect(result.isValid == true)
        #expect(result.shouldShowAnswer == true)
    }

    @Test("Source-grounded validator rejects missing citation")
    func sourceGroundedValidatorRejectsMissingCitation() {
        let output = SourceGroundedAnswerOutput(
            answer: "The waterfall you loved was in Guam.",
            sourceIdentifiers: [],
            insufficientEvidence: false
        )

        let result = SourceGroundedAnswerValidator().validate(
            output,
            candidateSourceIdentifiers: []
        )

        #expect(result.isValid == false)
        #expect(result.reason?.localizedCaseInsensitiveContains("no source") == true)
    }

    @Test("Source-grounded validator rejects malformed citation")
    func sourceGroundedValidatorRejectsMalformedCitation() {
        let output = SourceGroundedAnswerOutput(
            answer: "The waterfall you loved was in Guam.",
            sourceIdentifiers: ["not-a-uuid"],
            insufficientEvidence: false
        )

        let result = SourceGroundedAnswerValidator().validate(
            output,
            candidateSourceIdentifiers: ["not-a-uuid"]
        )

        #expect(result.isValid == false)
        #expect(result.reason?.localizedCaseInsensitiveContains("malformed") == true)
    }

    @Test("Source-grounded validator rejects citation outside returned sources")
    func sourceGroundedValidatorRejectsCitationOutsideReturnedSources() {
        let cited = UUID().uuidString
        let candidate = UUID().uuidString
        let output = SourceGroundedAnswerOutput(
            answer: "The waterfall you loved was in Guam.",
            sourceIdentifiers: [cited],
            insufficientEvidence: false
        )

        let result = SourceGroundedAnswerValidator().validate(
            output,
            candidateSourceIdentifiers: [candidate]
        )

        #expect(result.isValid == false)
        #expect(result.reason?.localizedCaseInsensitiveContains("outside the retrieval set") == true)
    }

    @Test("Source-grounded validator fails closed for insufficient evidence")
    func sourceGroundedValidatorFailsClosedForInsufficientEvidence() {
        let id = UUID().uuidString
        let output = SourceGroundedAnswerOutput(
            answer: "The waterfall might have been in Guam.",
            sourceIdentifiers: [id],
            insufficientEvidence: true
        )

        let result = SourceGroundedAnswerValidator().validate(
            output,
            candidateSourceIdentifiers: [id]
        )

        #expect(result.isValid == false)
        #expect(result.shouldShowAnswer == false)
        #expect(result.reason?.localizedCaseInsensitiveContains("insufficient evidence") == true)
    }

    @MainActor
    private static func makeMemory(_ text: String) -> MemoryRecord {
        MemoryRecord(
            rawInput: text,
            summary: text,
            memoryType: .fact,
            persistenceScore: 0.8,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.9,
            confidence: 0.9
        )
    }
}
