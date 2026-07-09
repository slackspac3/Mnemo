import Foundation
#if DEBUG && canImport(OSLog)
import OSLog
#endif
import MnemoCore
import MnemoMemory

/// Coordinates the full extraction pipeline for a raw capture.
/// Order of operations:
/// 1. Check corroboration (VectorBridge query)
/// 2. Build extraction prompt
/// 3. Attempt model extraction hooks (currently stubbed)
/// 4. If confidence < threshold AND cloud permitted: escalate
/// 5. Parse JSON response into ExtractionResult
/// 6. Return result with correct processingTier and modalityThresholdUsed
public final class ExtractionEngine: Sendable {
    #if DEBUG && canImport(OSLog)
    private static let debugLogger = Logger(
        subsystem: "com.thinkact.mnemo",
        category: "DebugDiagnostics"
    )
    #endif

    private let foundationLoader: FoundationModelLoader
    private let mlxLoader: MLXModelLoader
    private let promptBuilder: ExtractionPromptBuilder
    private let jsonParser: ExtractionJSONParser
    private let anonymisation: AnonymisationLayer
    private let vectorBridge: VectorBridge
    private let aiCoreFlags: AICoreFlags

    public init(
        foundationLoader: FoundationModelLoader = .shared,
        mlxLoader: MLXModelLoader = .shared,
        promptBuilder: ExtractionPromptBuilder = ExtractionPromptBuilder(),
        jsonParser: ExtractionJSONParser = ExtractionJSONParser(),
        anonymisation: AnonymisationLayer = AnonymisationLayer(),
        vectorBridge: VectorBridge = .shared,
        aiCoreFlags: AICoreFlags = .testFlightDefault
    ) {
        self.foundationLoader = foundationLoader
        self.mlxLoader = mlxLoader
        self.promptBuilder = promptBuilder
        self.jsonParser = jsonParser
        self.anonymisation = anonymisation
        self.vectorBridge = vectorBridge
        self.aiCoreFlags = aiCoreFlags
    }

    /// Extract structured memory from raw text input.
    /// - Parameters:
    ///   - rawText: The normalised text from any capture modality
    ///   - source: Which modality produced this text
    ///   - userContext: Optional clarifying context from the user
    ///   - threshold: The user's learned modality-specific confidence threshold
    ///   - cloudPermitted: Whether cloud escalation is allowed for this user
    /// - Returns: ExtractionResult with processingTier indicating where it was processed
    public func extract(
        rawText: String,
        source: InputSource,
        userContext: String? = nil,
        threshold: Double,
        cloudPermitted: Bool = false
    ) async throws -> ExtractionResult {

        let prompt = promptBuilder.buildExtractionPrompt(
            rawText: rawText,
            userContext: userContext
        )

        // Attempt Foundation Models only when the AI Core prototype is explicitly enabled.
        if aiCoreFlags.aiCoreEnabled,
           aiCoreFlags.foundationModelsEnabled {
            do {
                if let response = try await foundationLoader.generate(prompt: prompt, maxTokens: 260) {
                    debugLog("Extraction foundationModelsResponse=true source=\(source.rawValue)")
                    let result = jsonParser.parse(
                        json: response,
                        source: source,
                        processingTier: .onDevice,
                        thresholdUsed: threshold
                    )
                    debugLog("Extraction foundationModelsResult confidence=\(result.confidence) threshold=\(threshold) tags=\(result.tags.joined(separator: ","))")
                    if result.confidence >= threshold {
                        return result
                    }
                    return reviewSuggested(result)
                }
                debugLog("Extraction foundationModelsResponse=false source=\(source.rawValue)")
            } catch {
                debugLog("Extraction foundationModelsError source=\(source.rawValue) error=\(error.localizedDescription)")
            }
        }

        // Attempt MLX only when the AI Core prototype is explicitly enabled.
        if aiCoreFlags.aiCoreEnabled,
           aiCoreFlags.mlxAnswerComposerEnabled {
            do {
                if let response = try await mlxLoader.generate(prompt: prompt) {
                    debugLog("Extraction mlxResponse=true source=\(source.rawValue)")
                    let result = jsonParser.parse(
                        json: response,
                        source: source,
                        processingTier: .onDevice,
                        thresholdUsed: threshold
                    )
                    debugLog("Extraction mlxResult confidence=\(result.confidence) threshold=\(threshold) tags=\(result.tags.joined(separator: ","))")
                    if result.confidence >= threshold {
                        return result
                    }
                    return reviewSuggested(result)
                }
                debugLog("Extraction mlxResponse=false source=\(source.rawValue)")
            } catch {
                debugLog("Extraction mlxError source=\(source.rawValue) error=\(error.localizedDescription)")
            }
        }

        // Cloud escalation path
        if cloudPermitted {
            let anonymisedText = anonymisation.anonymise(rawText)
            let cloudPrompt = promptBuilder.buildExtractionPrompt(
                rawText: anonymisedText,
                userContext: userContext
            )
            // Cloud provider is not configured in this build.
            // Fall through to the low-confidence local review result.
            _ = cloudPrompt
        }

        // Final fallback: return low-confidence result from raw input for user review.
        debugLog("Extraction fallback=rawText source=\(source.rawValue)")
        return ExtractionResult(
            summary: String(rawText.prefix(200)),
            memoryType: .fact,
            persistenceScore: 0.3,
            confidence: 0.2,
            processingTier: .onDevice,
            modalityThresholdUsed: threshold,
            tags: ["needs-review"]
        )
    }

    private func reviewSuggested(_ result: ExtractionResult) -> ExtractionResult {
        guard result.confidence < result.modalityThresholdUsed else { return result }

        let tags = result.tags.contains("needs-review")
            ? result.tags
            : Array((result.tags + ["needs-review"]).prefix(3))

        return ExtractionResult(
            summary: result.summary,
            memoryType: result.memoryType,
            persistenceScore: result.persistenceScore,
            suggestedExpiry: result.suggestedExpiry,
            confidence: result.confidence,
            processingTier: result.processingTier,
            modalityThresholdUsed: result.modalityThresholdUsed,
            tags: tags
        )
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[MnemoDebug] \(message)")
        #if canImport(OSLog)
        Self.debugLogger.debug("[MnemoDebug] \(message, privacy: .public)")
        #endif
        #endif
    }
}
