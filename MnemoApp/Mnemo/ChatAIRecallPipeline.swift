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
    let retrievedSourceCount: Int
    let resolvedSourceCount: Int
    let rawModelSourceIdentifiers: [String]
    let mappedSourceIdentifiers: [String]
    let validationError: String?
    let fidelityValidationError: String?
    let rawModelAnswer: String
    let errorMessage: String?
}

enum ChatAIRecallPipeline {
    @MainActor
    static func attemptAnswer(
        query: String,
        context: ModelContext
    ) async -> ChatAIRecallResult? {
        guard DebugAIChatSetting.usesLocalAIFirst else { return nil }

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
        do {
            let details = try await answerDetails(query: query, context: context)
            return details.diagnostic(answered: true, errorMessage: nil)
        } catch let error as LocalAIChatFailure {
            return error.diagnostic ?? failureDiagnostic(error.localizedDescription)
        } catch {
            return failureDiagnostic(error.localizedDescription)
        }
    }

    @MainActor
    private static func answer(
        query: String,
        context: ModelContext
    ) async throws -> ChatAIRecallResult {
        try await answerDetails(query: query, context: context).result
    }

    @MainActor
    private static func answerDetails(
        query: String,
        context: ModelContext
    ) async throws -> ChatAIRecallAnswerDetails {
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

    private static func failureDiagnostic(_ message: String) -> ChatAIRecallDiagnosticResult {
        ChatAIRecallDiagnosticResult(
            answered: false,
            answer: "",
            citedSourceIdentifiers: [],
            retrievedSourceCount: 0,
            resolvedSourceCount: 0,
            rawModelSourceIdentifiers: [],
            mappedSourceIdentifiers: [],
            validationError: nil,
            fidelityValidationError: nil,
            rawModelAnswer: "",
            errorMessage: message
        )
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    @MainActor
    private static func answerWithFoundationModels(
        query: String,
        context: ModelContext
    ) async throws -> ChatAIRecallAnswerDetails {
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

        let aliasedSources = payloads.enumerated().map { index, payload in
            AliasedMemorySource(alias: "S\(index + 1)", payload: payload)
        }
        let output = try await generateAnswer(
            model: model,
            query: query,
            sources: aliasedSources
        )
        var diagnostics = LocalAIChatDiagnostics(
            retrievedSourceCount: sourceIdentifiers.count,
            resolvedSourceCount: payloads.count,
            rawModelSourceIdentifiers: output.sourceIdentifiers,
            rawModelAnswer: output.answer
        )

        let mappedOutput: SourceGroundedAnswerOutput
        do {
            mappedOutput = try SourceAliasCitationMapper(
                mappings: aliasedSources.map { source in
                    SourceAliasMapping(
                        alias: source.alias,
                        sourceIdentifier: source.payload.sourceIdentifier
                    )
                }
            ).mapToSourceIdentifiers(output)
            diagnostics.mappedSourceIdentifiers = mappedOutput.sourceIdentifiers
        } catch {
            let message = error.localizedDescription
            diagnostics.validationError = message
            throw LocalAIChatFailure(
                message: message,
                diagnostic: diagnostics.result(
                    answered: false,
                    errorMessage: message
                )
            )
        }

        let candidateSourceIdentifiers = Set(payloads.map(\.sourceIdentifier))
        let validation = SourceGroundedAnswerValidator().validate(
            mappedOutput,
            candidateSourceIdentifiers: candidateSourceIdentifiers
        )
        guard validation.isValid, validation.shouldShowAnswer else {
            let reason = validation.reason ?? "Invalid model output."
            diagnostics.validationError = reason
            throw LocalAIChatFailure(
                message: reason,
                diagnostic: diagnostics.result(
                    answered: false,
                    errorMessage: reason
                )
            )
        }

        var citedPayloads: [MemorySourceCardPayload] = []
        for sourceIdentifier in mappedOutput.sourceIdentifiers {
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

        let fidelity = SourceGroundedAnswerFidelityValidator().validate(
            answer: mappedOutput.answer,
            question: query,
            sourceSummaries: citedPayloads.map(\.summary)
        )
        guard fidelity.isValid else {
            let reason = fidelity.reason ?? "Answer fidelity validation failed."
            diagnostics.fidelityValidationError = reason
            throw LocalAIChatFailure(
                message: reason,
                diagnostic: diagnostics.result(
                    answered: false,
                    errorMessage: reason
                )
            )
        }

        let result = ChatAIRecallResult(
            text: mappedOutput.answer.trimmingCharacters(in: .whitespacesAndNewlines),
            citedMemoryIds: citedPayloads.map(\.id),
            citations: citedPayloads.map { payload in
                ChatAIRecallResult.Citation(
                    id: payload.id,
                    summary: payload.summary,
                    source: payload.source
                )
            }
        )

        return ChatAIRecallAnswerDetails(
            result: result,
            diagnostics: diagnostics
        )
    }

    @available(iOS 26.0, *)
    private static func generateAnswer(
        model: SystemLanguageModel,
        query: String,
        sources: [AliasedMemorySource]
    ) async throws -> SourceGroundedAnswerOutput {
        let promptPayload = SourceGroundedAnswerPromptBuilder().build(
            query: query,
            sources: sources.map { source in
                SourceGroundedPromptSource(
                    alias: source.alias,
                    source: source.payload.source,
                    summary: source.payload.summary
                )
            }
        )
        let session = LanguageModelSession(
            model: model,
            instructions: promptPayload.instructions
        )
        let response = try await session.respond(
            to: promptPayload.prompt,
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

    private struct AliasedMemorySource {
        let alias: String
        let payload: MemorySourceCardPayload
    }

    private struct ChatAIRecallAnswerDetails {
        let result: ChatAIRecallResult
        let diagnostics: LocalAIChatDiagnostics

        func diagnostic(
            answered: Bool,
            errorMessage: String?
        ) -> ChatAIRecallDiagnosticResult {
            diagnostics.result(
                answered: answered,
                answer: result.text,
                citedSourceIdentifiers: result.citations.map { $0.id.uuidString },
                errorMessage: errorMessage
            )
        }
    }

    private struct LocalAIChatDiagnostics {
        var retrievedSourceCount: Int = 0
        var resolvedSourceCount: Int = 0
        var rawModelSourceIdentifiers: [String] = []
        var mappedSourceIdentifiers: [String] = []
        var validationError: String?
        var fidelityValidationError: String?
        var rawModelAnswer: String = ""

        func result(
            answered: Bool,
            answer: String = "",
            citedSourceIdentifiers: [String] = [],
            errorMessage: String?
        ) -> ChatAIRecallDiagnosticResult {
            ChatAIRecallDiagnosticResult(
                answered: answered,
                answer: answer,
                citedSourceIdentifiers: citedSourceIdentifiers,
                retrievedSourceCount: retrievedSourceCount,
                resolvedSourceCount: resolvedSourceCount,
                rawModelSourceIdentifiers: rawModelSourceIdentifiers,
                mappedSourceIdentifiers: mappedSourceIdentifiers,
                validationError: validationError,
                fidelityValidationError: fidelityValidationError,
                rawModelAnswer: rawModelAnswer,
                errorMessage: errorMessage
            )
        }
    }

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

    private struct LocalAIChatFailure: LocalizedError {
        let message: String
        let diagnostic: ChatAIRecallDiagnosticResult?

        var errorDescription: String? {
            message
        }
    }
}
#endif
