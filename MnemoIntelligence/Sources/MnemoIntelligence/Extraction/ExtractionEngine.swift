import Foundation
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

    private let foundationLoader: FoundationModelLoader
    private let mlxLoader: MLXModelLoader
    private let promptBuilder: ExtractionPromptBuilder
    private let jsonParser: ExtractionJSONParser
    private let anonymisation: AnonymisationLayer
    private let vectorBridge: VectorBridge

    public init(
        foundationLoader: FoundationModelLoader = .shared,
        mlxLoader: MLXModelLoader = .shared,
        promptBuilder: ExtractionPromptBuilder = ExtractionPromptBuilder(),
        jsonParser: ExtractionJSONParser = ExtractionJSONParser(),
        anonymisation: AnonymisationLayer = AnonymisationLayer(),
        vectorBridge: VectorBridge = .shared
    ) {
        self.foundationLoader = foundationLoader
        self.mlxLoader = mlxLoader
        self.promptBuilder = promptBuilder
        self.jsonParser = jsonParser
        self.anonymisation = anonymisation
        self.vectorBridge = vectorBridge
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

        // Attempt Foundation Models hook first. It returns nil until production inference is wired.
        if let response = try await foundationLoader.generate(prompt: prompt) {
            let result = jsonParser.parse(
                json: response,
                source: source,
                processingTier: .onDevice,
                thresholdUsed: threshold
            )
            if result.confidence >= threshold {
                return result
            }
        }

        // Attempt MLX fallback hook. It returns nil until production inference is wired.
        if let response = try await mlxLoader.generate(prompt: prompt) {
            let result = jsonParser.parse(
                json: response,
                source: source,
                processingTier: .onDevice,
                thresholdUsed: threshold
            )
            if result.confidence >= threshold {
                return result
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
}
