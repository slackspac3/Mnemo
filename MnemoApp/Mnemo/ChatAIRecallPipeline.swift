#if DEBUG
import Foundation
import SwiftData
import MnemoIntelligence
import MnemoMemory

#if canImport(FoundationModels)
import FoundationModels
#endif

struct ChatAIRecallResult: Equatable, Sendable {
    let text: String
    let citedMemoryIds: [UUID]
    let citations: [Citation]

    struct Citation: Equatable, Sendable {
        let id: UUID
        let summary: String
        let source: String
    }
}

struct ChatAIRecallDiagnosticResult: Equatable, Sendable {
    let answered: Bool
    let answer: String
    let citedSourceIdentifiers: [String]
    let errorMessage: String?
}

enum ChatAIRecallPipeline {
    @MainActor
    static func attemptAnswer(
        query: String,
        context: ModelContext
    ) async -> ChatAIRecallResult? {
        guard DebugAIChatSetting.isEnabled else { return nil }

        do {
            return try await answer(query: query, context: context)
        } catch {
            return nil
        }
    }

    @MainActor
    static func runManualTest(
        query: String,
        context: ModelContext
    ) async -> ChatAIRecallDiagnosticResult {
        guard DebugAIChatSetting.isEnabled else {
            return ChatAIRecallDiagnosticResult(
                answered: false,
                answer: "",
                citedSourceIdentifiers: [],
                errorMessage: "Local AI Chat is off."
            )
        }

        do {
            let result = try await answer(query: query, context: context)
            return ChatAIRecallDiagnosticResult(
                answered: true,
                answer: result.text,
                citedSourceIdentifiers: result.citations.map { $0.id.uuidString },
                errorMessage: nil
            )
        } catch {
            return ChatAIRecallDiagnosticResult(
                answered: false,
                answer: "",
                citedSourceIdentifiers: [],
                errorMessage: error.localizedDescription
            )
        }
    }

    @MainActor
    private static func answer(
        query: String,
        context: ModelContext
    ) async throws -> ChatAIRecallResult {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw LocalAIChatError.emptyQuery
        }

        guard #available(iOS 26.0, *) else {
            throw LocalAIChatError.foundationModelsUnavailable("iOS 26.0 or later is required.")
        }

        #if canImport(FoundationModels)
        return try await answerWithFoundationModels(query: trimmedQuery, context: context)
        #else
        throw LocalAIChatError.foundationModelsUnavailable("FoundationModels framework is unavailable in this build.")
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    @MainActor
    private static func answerWithFoundationModels(
        query: String,
        context: ModelContext
    ) async throws -> ChatAIRecallResult {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw LocalAIChatError.foundationModelsUnavailable(
                "Foundation Models unavailable: \(availabilityDescription(model.availability))."
            )
        }

        try await MemoryCRUD.backfillSearchIndex(in: context)

        let indexer = CoreSpotlightMemoryIndexer()
        let service = MemorySearchIndexingService(
            flags: .debugCoreSpotlight,
            indexer: indexer,
            queryer: indexer
        )
        let sourceIdentifiers = try await sourceIdentifiers(
            matching: query,
            service: service,
            limit: 5
        )
        guard !sourceIdentifiers.isEmpty else {
            throw LocalAIChatError.noCandidateSources
        }

        let resolver = MemorySourceCardResolver(indexingService: service)
        var payloads: [MemorySourceCardPayload] = []
        for sourceIdentifier in sourceIdentifiers {
            guard let payload = try resolver.resolve(
                sourceIdentifier: sourceIdentifier,
                in: context
            ) else { continue }
            if !payloads.contains(where: { $0.sourceIdentifier == payload.sourceIdentifier }) {
                payloads.append(payload)
            }
            if payloads.count == 5 { break }
        }
        guard !payloads.isEmpty else {
            throw LocalAIChatError.noResolvedSources
        }

        let output = try await generateAnswer(
            model: model,
            query: query,
            payloads: payloads
        )
        let candidateSourceIdentifiers = Set(payloads.map(\.sourceIdentifier))
        let validation = SourceGroundedAnswerValidator().validate(
            output,
            candidateSourceIdentifiers: candidateSourceIdentifiers
        )
        guard validation.isValid, validation.shouldShowAnswer else {
            throw LocalAIChatError.invalidModelOutput(validation.reason ?? "Invalid model output.")
        }

        var citedPayloads: [MemorySourceCardPayload] = []
        for sourceIdentifier in output.sourceIdentifiers {
            guard let payload = try resolver.resolve(
                sourceIdentifier: sourceIdentifier,
                in: context
            ) else {
                throw LocalAIChatError.invalidModelOutput("Cited source no longer resolves.")
            }
            citedPayloads.append(payload)
        }
        guard !citedPayloads.isEmpty else {
            throw LocalAIChatError.invalidModelOutput("No cited sources resolved.")
        }

        return ChatAIRecallResult(
            text: output.answer.trimmingCharacters(in: .whitespacesAndNewlines),
            citedMemoryIds: citedPayloads.map(\.id),
            citations: citedPayloads.map { payload in
                ChatAIRecallResult.Citation(
                    id: payload.id,
                    summary: payload.summary,
                    source: payload.source
                )
            }
        )
    }

    @available(iOS 26.0, *)
    private static func generateAnswer(
        model: SystemLanguageModel,
        query: String,
        payloads: [MemorySourceCardPayload]
    ) async throws -> SourceGroundedAnswerOutput {
        let instructions = """
        You are Mnemo's local memory answerer.
        Answer only from the provided memories.
        Do not use outside knowledge.
        Do not guess.
        Return exactly one JSON object and no Markdown.
        """
        let memoryBlock = payloads.map { payload in
            """
            sourceIdentifier: \(payload.sourceIdentifier)
            source: \(payload.source)
            summary: \(payload.summary)
            """
        }.joined(separator: "\n\n")
        let prompt = """
        Memories:
        \(memoryBlock)

        Question: \(query)

        Return this JSON shape:
        {
          "answer": "short answer supported by the memories",
          "sourceIdentifiers": ["source identifier strings used"],
          "insufficientEvidence": false
        }

        If the memories do not support an answer, return:
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
                maximumResponseTokens: 220
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
    private static func sourceIdentifiers(
        matching query: String,
        service: MemorySearchIndexingService,
        limit: Int
    ) async throws -> [String] {
        let variants = searchVariants(for: query)
        var orderedIDs: [String] = []

        for attempt in 0..<3 {
            for variant in variants {
                let ids = try await service.sourceIdentifiersIfNeeded(
                    matching: variant,
                    limit: limit
                )
                for id in ids where !orderedIDs.contains(id) {
                    orderedIDs.append(id)
                }
                if orderedIDs.count >= limit {
                    return Array(orderedIDs.prefix(limit))
                }
            }

            if !orderedIDs.isEmpty {
                return orderedIDs
            }

            if attempt < 2 {
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        }

        return orderedIDs
    }

    private static func searchVariants(for query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let stopWords: Set<String> = [
            "what", "where", "when", "which", "who", "whose", "about",
            "does", "did", "was", "were", "have", "has", "had", "saved",
            "memory", "remember", "tell", "with", "from", "that", "this",
            "the", "and", "you", "your", "mine", "my"
        ]
        let tokens = trimmed
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { token in
                token.count > 3 && !stopWords.contains(token)
            }

        var variants = [trimmed]
        for token in tokens where !variants.contains(token) {
            variants.append(token)
        }
        return Array(variants.prefix(8))
    }

    private enum LocalAIChatError: LocalizedError {
        case emptyQuery
        case foundationModelsUnavailable(String)
        case noCandidateSources
        case noResolvedSources
        case invalidModelOutput(String)

        var errorDescription: String? {
            switch self {
            case .emptyQuery:
                return "Question is empty."
            case .foundationModelsUnavailable(let message):
                return message
            case .noCandidateSources:
                return "No Core Spotlight source identifiers were returned."
            case .noResolvedSources:
                return "No returned source identifiers resolved to active memories."
            case .invalidModelOutput(let message):
                return message
            }
        }
    }
}
#endif
