import Foundation
import SwiftData
import MnemoCore
import MnemoIntelligence
import MnemoMemory

#if DEBUG && canImport(FoundationModels)
import FoundationModels
#endif

#if DEBUG
struct FoundationModelsMemorySmokeTestResult: Equatable, Sendable {
    let available: Bool
    let indexed: Bool
    let queried: Bool
    let sourceCardResolved: Bool
    let modelAnswered: Bool
    let citationsValid: Bool
    let answer: String
    let durationMs: Double
    let errorMessage: String?
}

enum FoundationModelsMemorySmokeTest {
    static let launchArgument = "--run-foundation-models-memory-smoke"

    static var shouldRunFromLaunchArguments: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    @MainActor
    static func run() async -> FoundationModelsMemorySmokeTestResult {
        let startedAt = Date()

        guard #available(iOS 26.0, *) else {
            return unavailableResult(
                startedAt: startedAt,
                error: "Foundation Models require iOS 26.0 or later."
            )
        }

        #if canImport(FoundationModels)
        return await runWithFoundationModels(startedAt: startedAt)
        #else
        return unavailableResult(
            startedAt: startedAt,
            error: "FoundationModels framework is unavailable in this build."
        )
        #endif
    }

    private static func unavailableResult(
        startedAt: Date,
        error: String
    ) -> FoundationModelsMemorySmokeTestResult {
        FoundationModelsMemorySmokeTestResult(
            available: false,
            indexed: false,
            queried: false,
            sourceCardResolved: false,
            modelAnswered: false,
            citationsValid: false,
            answer: "",
            durationMs: Date().timeIntervalSince(startedAt) * 1_000,
            errorMessage: error
        )
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    @MainActor
    private static func runWithFoundationModels(
        startedAt: Date
    ) async -> FoundationModelsMemorySmokeTestResult {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return unavailableResult(
                startedAt: startedAt,
                error: "Foundation Models unavailable: \(availabilityDescription(model.availability))."
            )
        }

        let context = MemoryStore.shared.container.mainContext
        let indexer = CoreSpotlightMemoryIndexer()
        let service = MemorySearchIndexingService(
            flags: .debugCoreSpotlight,
            indexer: indexer,
            queryer: indexer
        )
        let token = "mnemofoundationmodelsmoke\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
        let record = MemoryRecord(
            rawInput: "I loved the waterfall in Guam.",
            summary: "I loved the waterfall in Guam.",
            memoryType: .fact,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.95,
            tags: ["foundation-models-smoke", token]
        )

        var indexed = false
        var queried = false
        var sourceCardResolved = false
        var modelAnswered = false
        var citationsValid = false
        var answer = ""

        do {
            try await MemoryCRUD.insertAndIndex(
                record,
                into: context,
                searchIndexingFlags: .debugCoreSpotlight,
                searchIndexer: indexer
            )
            indexed = true

            let sourceIdentifier = try await waitForSourceIdentifier(
                record.id,
                matching: token,
                service: service
            )
            queried = sourceIdentifier == record.id.uuidString

            let sourceCandidate = MemorySearchSourceCandidate(
                sourceIdentifier: sourceIdentifier ?? record.id.uuidString,
                title: "Untrusted Foundation Models smoke title",
                snippet: "Untrusted Foundation Models smoke snippet"
            )
            let sourcePayload = try MemorySourceCardResolver(
                indexingService: service
            ).resolve(candidate: sourceCandidate, in: context)
            sourceCardResolved = sourcePayload?.id == record.id &&
                sourcePayload?.sourceIdentifier == record.id.uuidString &&
                sourcePayload?.summary == record.summary &&
                sourcePayload?.summary != sourceCandidate.title &&
                sourcePayload?.summary != sourceCandidate.snippet

            guard let sourcePayload else {
                throw SmokeFailure.sourceCardResolutionFailed
            }

            let modelOutput = try await generateAnswer(
                model: model,
                sourcePayload: sourcePayload
            )
            answer = modelOutput.answer.trimmingCharacters(in: .whitespacesAndNewlines)
            modelAnswered = !answer.isEmpty &&
                !modelOutput.insufficientEvidence &&
                answer.localizedCaseInsensitiveContains("Guam")

            let validation = SourceGroundedAnswerValidator().validate(
                modelOutput,
                candidateSourceIdentifiers: [sourcePayload.sourceIdentifier]
            )
            let citedSourceResolves = try modelOutput.sourceIdentifiers.allSatisfy { identifier in
                try MemorySourceCardResolver(indexingService: service)
                    .resolve(sourceIdentifier: identifier, in: context) != nil
            }
            citationsValid = validation.isValid &&
                Set(modelOutput.sourceIdentifiers) == Set([sourcePayload.sourceIdentifier]) &&
                citedSourceResolves

            try await cleanup(recordID: record.id, indexer: indexer, context: context)

            let passed = indexed && queried && sourceCardResolved &&
                modelAnswered && citationsValid
            return FoundationModelsMemorySmokeTestResult(
                available: true,
                indexed: indexed,
                queried: queried,
                sourceCardResolved: sourceCardResolved,
                modelAnswered: modelAnswered,
                citationsValid: citationsValid,
                answer: singleLine(answer),
                durationMs: Date().timeIntervalSince(startedAt) * 1_000,
                errorMessage: passed ? nil : "Foundation Models memory smoke did not satisfy all checks."
            )
        } catch {
            try? await cleanup(recordID: record.id, indexer: indexer, context: context)
            return FoundationModelsMemorySmokeTestResult(
                available: true,
                indexed: indexed,
                queried: queried,
                sourceCardResolved: sourceCardResolved,
                modelAnswered: modelAnswered,
                citationsValid: citationsValid,
                answer: singleLine(answer),
                durationMs: Date().timeIntervalSince(startedAt) * 1_000,
                errorMessage: error.localizedDescription
            )
        }
    }

    @available(iOS 26.0, *)
    private static func generateAnswer(
        model: SystemLanguageModel,
        sourcePayload: MemorySourceCardPayload
    ) async throws -> SourceGroundedAnswerOutput {
        let instructions = """
        You are Mnemo's local memory answer smoke test.
        Answer only from the provided memory.
        Do not guess.
        Return exactly one JSON object and no Markdown.
        """
        let prompt = """
        Memory:
        sourceIdentifier: \(sourcePayload.sourceIdentifier)
        summary: \(sourcePayload.summary)

        Question: Where was the waterfall I loved?

        Return this JSON shape:
        {
          "answer": "The waterfall you loved was in Guam.",
          "sourceIdentifiers": ["\(sourcePayload.sourceIdentifier)"],
          "insufficientEvidence": false
        }

        If the memory does not support the answer, return:
        {
          "answer": "",
          "sourceIdentifiers": [],
          "insufficientEvidence": true
        }
        """
        let session = LanguageModelSession(
            model: model,
            instructions: instructions
        )
        let response = try await session.respond(
            to: prompt,
            options: GenerationOptions(
                sampling: .greedy,
                temperature: 0.0,
                maximumResponseTokens: 160
            )
        )
        return try SourceGroundedAnswerParser().parse(response.content)
    }

    @available(iOS 26.0, *)
    private static func availabilityDescription(
        _ availability: SystemLanguageModel.Availability
    ) -> String {
        switch availability {
        case .available:
            return "available"
        case .unavailable(.deviceNotEligible):
            return "deviceNotEligible"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "appleIntelligenceNotEnabled"
        case .unavailable(.modelNotReady):
            return "modelNotReady"
        @unknown default:
            return "unknown"
        }
    }
    #endif

    @MainActor
    private static func waitForSourceIdentifier(
        _ id: UUID,
        matching query: String,
        service: MemorySearchIndexingService
    ) async throws -> String? {
        for _ in 0..<12 {
            let ids = try await service.sourceIdentifiersIfNeeded(matching: query, limit: 10)
            if ids.contains(id.uuidString) {
                return id.uuidString
            }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        return nil
    }

    @MainActor
    private static func cleanup(
        recordID: UUID,
        indexer: CoreSpotlightMemoryIndexer,
        context: ModelContext
    ) async throws {
        try await MemoryCRUD.deletePermanently(
            id: recordID,
            in: context,
            searchIndexingFlags: .debugCoreSpotlight,
            searchIndexer: indexer
        )
        try await MemoryCRUD.resetSearchIndexItems(searchIndexer: indexer)
        DebugLocalAIBackfillState.isComplete = false
    }

    private static func singleLine(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\"", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private enum SmokeFailure: LocalizedError {
        case sourceCardResolutionFailed

        var errorDescription: String? {
            switch self {
            case .sourceCardResolutionFailed:
                return "Source card resolution failed."
            }
        }
    }
}
#endif
