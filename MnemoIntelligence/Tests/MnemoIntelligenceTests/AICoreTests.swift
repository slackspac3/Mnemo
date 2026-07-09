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

    @Test("Source-grounded validator rejects empty answer")
    func sourceGroundedValidatorRejectsEmptyAnswer() {
        let id = UUID().uuidString
        let output = SourceGroundedAnswerOutput(
            answer: "  ",
            sourceIdentifiers: [id],
            insufficientEvidence: false
        )

        let result = SourceGroundedAnswerValidator().validate(
            output,
            candidateSourceIdentifiers: [id]
        )

        #expect(result.isValid == false)
        #expect(result.shouldShowAnswer == false)
        #expect(result.reason?.localizedCaseInsensitiveContains("empty answer") == true)
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

    @Test("Source alias mapper maps S1 to the correct UUID")
    func sourceAliasMapperMapsS1ToCorrectUUID() throws {
        let id = UUID().uuidString
        let output = SourceGroundedAnswerOutput(
            answer: "Your favourite butter is Ille & Vire.",
            sourceIdentifiers: ["S1"],
            insufficientEvidence: false
        )

        let mapped = try SourceAliasCitationMapper(mappings: [
            SourceAliasMapping(alias: "S1", sourceIdentifier: id)
        ]).mapToSourceIdentifiers(output)

        #expect(mapped.sourceIdentifiers == [id])
        #expect(mapped.answer == output.answer)
    }

    @Test("Source alias mapper maps S2 to the correct UUID")
    func sourceAliasMapperMapsS2ToCorrectUUID() throws {
        let first = UUID().uuidString
        let second = UUID().uuidString
        let output = SourceGroundedAnswerOutput(
            answer: "The second source has the answer.",
            sourceIdentifiers: ["S2"],
            insufficientEvidence: false
        )

        let mapped = try SourceAliasCitationMapper(mappings: [
            SourceAliasMapping(alias: "S1", sourceIdentifier: first),
            SourceAliasMapping(alias: "S2", sourceIdentifier: second)
        ]).mapToSourceIdentifiers(output)

        #expect(mapped.sourceIdentifiers == [second])
    }

    @Test("Source alias mapper rejects unknown alias")
    func sourceAliasMapperRejectsUnknownAlias() {
        let output = SourceGroundedAnswerOutput(
            answer: "Answer",
            sourceIdentifiers: ["S99"],
            insufficientEvidence: false
        )

        #expect(throws: SourceAliasCitationMappingError.unknownAlias("S99")) {
            _ = try SourceAliasCitationMapper(mappings: [
                SourceAliasMapping(alias: "S1", sourceIdentifier: UUID().uuidString)
            ]).mapToSourceIdentifiers(output)
        }
    }

    @Test("Source alias mapper rejects raw malformed UUID text")
    func sourceAliasMapperRejectsRawMalformedUUIDText() {
        let output = SourceGroundedAnswerOutput(
            answer: "Answer",
            sourceIdentifiers: ["not-a-uuid"],
            insufficientEvidence: false
        )

        #expect(throws: SourceAliasCitationMappingError.unknownAlias("not-a-uuid")) {
            _ = try SourceAliasCitationMapper(mappings: [
                SourceAliasMapping(alias: "S1", sourceIdentifier: UUID().uuidString)
            ]).mapToSourceIdentifiers(output)
        }
    }

    @Test("Source alias mapper rejects empty source identifiers")
    func sourceAliasMapperRejectsEmptySourceIdentifiers() {
        let output = SourceGroundedAnswerOutput(
            answer: "Answer",
            sourceIdentifiers: [],
            insufficientEvidence: false
        )

        #expect(throws: SourceAliasCitationMappingError.emptySourceIdentifiers) {
            _ = try SourceAliasCitationMapper(mappings: [
                SourceAliasMapping(alias: "S1", sourceIdentifier: UUID().uuidString)
            ]).mapToSourceIdentifiers(output)
        }
    }

    @Test("Source alias mapper rejects insufficient evidence")
    func sourceAliasMapperRejectsInsufficientEvidence() {
        let output = SourceGroundedAnswerOutput(
            answer: "",
            sourceIdentifiers: [],
            insufficientEvidence: true
        )

        #expect(throws: SourceAliasCitationMappingError.insufficientEvidence) {
            _ = try SourceAliasCitationMapper(mappings: [
                SourceAliasMapping(alias: "S1", sourceIdentifier: UUID().uuidString)
            ]).mapToSourceIdentifiers(output)
        }
    }

    @Test("Mapped UUID output still passes source-grounded validator")
    func mappedUUIDOutputStillPassesSourceGroundedValidator() throws {
        let id = UUID().uuidString
        let output = SourceGroundedAnswerOutput(
            answer: "Your favourite butter is Ille & Vire.",
            sourceIdentifiers: ["S1"],
            insufficientEvidence: false
        )

        let mapped = try SourceAliasCitationMapper(mappings: [
            SourceAliasMapping(alias: "S1", sourceIdentifier: id)
        ]).mapToSourceIdentifiers(output)
        let result = SourceGroundedAnswerValidator().validate(
            mapped,
            candidateSourceIdentifiers: [id]
        )

        #expect(result.isValid == true)
        #expect(result.shouldShowAnswer == true)
    }

    @Test("Source-grounded prompt asks for natural answers without raw UUIDs")
    func sourceGroundedPromptAsksForNaturalAnswersWithoutRawUUIDs() {
        let hiddenID = UUID().uuidString
        let prompt = SourceGroundedAnswerPromptBuilder().build(
            query: "What's my favourite butter?",
            sources: [
                SourceGroundedPromptSource(
                    alias: "S1",
                    source: "image",
                    summary: "My favourite butter. PRODUCED RANCE Ille &Vire® BEURRE GASTRONOMIQUE GOURMET BUTTER Unsalted Butter"
                ),
                SourceGroundedPromptSource(
                    alias: "S2",
                    source: "text",
                    summary: "The spare car key is in the black pouch."
                )
            ]
        )
        let combined = "\(prompt.instructions)\n\(prompt.prompt)"

        #expect(combined.localizedCaseInsensitiveContains("short natural sentence"))
        #expect(combined.localizedCaseInsensitiveContains("extract the relevant fact"))
        #expect(combined.localizedCaseInsensitiveContains("do not simply copy the full memory"))
        #expect(combined.localizedCaseInsensitiveContains("preserve important product names"))
        #expect(combined.localizedCaseInsensitiveContains("copy the exact wording from the memory"))
        #expect(combined.localizedCaseInsensitiveContains("do not translate, normalize, autocorrect, or improve OCR text"))
        #expect(combined.contains("If the memory says \"GOURMET\", do not answer \"Gourmand\"."))
        #expect(combined.localizedCaseInsensitiveContains("exact factual tokens are more important"))
        #expect(combined.localizedCaseInsensitiveContains("do not invent corrections for OCR errors"))
        #expect(combined.localizedCaseInsensitiveContains("do not use outside knowledge"))
        #expect(combined.contains("Source S1:"))
        #expect(combined.contains("Source S2:"))
        #expect(combined.contains("\"sourceIdentifiers\": [\"S1\"]"))
        #expect(combined.localizedCaseInsensitiveContains("source aliases"))
        #expect(!combined.contains(hiddenID))
    }

    @Test("Answer fidelity rejects translated product token")
    func answerFidelityRejectsTranslatedProductToken() {
        let result = SourceGroundedAnswerFidelityValidator().validate(
            answer: "Your favourite butter is Gourmand Butter.",
            question: "What's my favourite butter?",
            sourceSummaries: ["GOURMET BUTTER"]
        )

        #expect(result.isValid == false)
        #expect(result.reason == "Unsupported answer token: gourmand")
    }

    @Test("Answer fidelity accepts exact product wording")
    func answerFidelityAcceptsExactProductWording() {
        let result = SourceGroundedAnswerFidelityValidator().validate(
            answer: "Your butter is GOURMET BUTTER.",
            question: "What's my favourite butter?",
            sourceSummaries: ["GOURMET BUTTER"]
        )

        #expect(result.isValid == true)
    }

    @Test("Answer fidelity accepts waterfall location")
    func answerFidelityAcceptsWaterfallLocation() {
        let result = SourceGroundedAnswerFidelityValidator().validate(
            answer: "The waterfall was in Guam.",
            question: "Where was the waterfall?",
            sourceSummaries: ["I loved the waterfall in Guam"]
        )

        #expect(result.isValid == true)
    }

    @Test("Answer fidelity accepts parking spot")
    func answerFidelityAcceptsParkingSpot() {
        let result = SourceGroundedAnswerFidelityValidator().validate(
            answer: "P3, row C18.",
            question: "Where did I park?",
            sourceSummaries: ["At Dubai Mall, I parked in P3, row C18"]
        )

        #expect(result.isValid == true)
    }

    @Test("Answer fidelity accepts exact Wi-Fi password")
    func answerFidelityAcceptsExactWiFiPassword() {
        let result = SourceGroundedAnswerFidelityValidator().validate(
            answer: "coconut-sand-77",
            question: "What is the Wi-Fi password?",
            sourceSummaries: ["The beach house Wi-Fi password is coconut-sand-77"]
        )

        #expect(result.isValid == true)
    }

    @Test("Answer fidelity accepts printer ink code")
    func answerFidelityAcceptsPrinterInkCode() {
        let result = SourceGroundedAnswerFidelityValidator().validate(
            answer: "HP 305 black.",
            question: "What ink do I need?",
            sourceSummaries: ["HP 305 black"]
        )

        #expect(result.isValid == true)
    }

    @Test("Answer fidelity ignores helper words")
    func answerFidelityIgnoresHelperWords() {
        let result = SourceGroundedAnswerFidelityValidator().validate(
            answer: "It was in Guam because that is what you saved.",
            question: "Where was it?",
            sourceSummaries: ["Guam"]
        )

        #expect(result.isValid == true)
    }

    @Test("Answer fidelity guard does not weaken UUID validator")
    func answerFidelityGuardDoesNotWeakenUUIDValidator() {
        let output = SourceGroundedAnswerOutput(
            answer: "GOURMET BUTTER.",
            sourceIdentifiers: ["S1"],
            insufficientEvidence: false
        )
        let citationResult = SourceGroundedAnswerValidator().validate(
            output,
            candidateSourceIdentifiers: ["S1"]
        )
        let fidelityResult = SourceGroundedAnswerFidelityValidator().validate(
            answer: output.answer,
            question: "What's my favourite butter?",
            sourceSummaries: ["GOURMET BUTTER"]
        )

        #expect(citationResult.isValid == false)
        #expect(citationResult.reason?.localizedCaseInsensitiveContains("malformed") == true)
        #expect(fidelityResult.isValid == true)
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
