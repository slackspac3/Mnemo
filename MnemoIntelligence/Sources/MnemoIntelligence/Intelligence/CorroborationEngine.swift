import Foundation
import MnemoCore
import MnemoMemory

/// Checks for cross-modal corroboration before extraction.
/// Patent Candidate 3 — composite confidence from multiple input modalities.
/// Queries VectorBridge for semantically similar memories from different modalities.
/// Returns a CorroborationResult indicating whether to create, update, or conflict.
public final class CorroborationEngine: Sendable {

    private let vectorBridge: VectorBridge

    public init(vectorBridge: VectorBridge = .shared) {
        self.vectorBridge = vectorBridge
    }

    /// Check for corroboration before storing a new capture.
    public func check(
        captureText: String,
        source: InputSource
    ) async throws -> CorroborationResult {
        // Generate a simple embedding proxy for Phase 6.
        // Phase 12: replace with real MLX embedding model call.
        let embedding = simpleEmbedding(from: captureText)

        let corroboratingIds = try await vectorBridge.findCorroborating(
            embedding: embedding,
            excludingSource: source,
            threshold: 0.85
        )

        guard let existingId = corroboratingIds.first else {
            return CorroborationResult(
                corroborationType: .noMatch,
                persistenceDelta: 0.0
            )
        }

        // In Phase 6, we use a simple heuristic:
        // if a corroborating memory exists, treat it as confirming.
        // Phase 12: LLM semantic comparison to distinguish confirms vs contradicts.
        return CorroborationResult(
            existingMemoryId: existingId,
            corroborationType: .confirms,
            persistenceDelta: 0.15
        )
    }

    /// Apply corroboration — update persistence score on existing memory.
    public func applyCorroboration(
        _ result: CorroborationResult,
        to memoryId: UUID,
        in context: any Sendable
    ) async {
        _ = (result, memoryId, context)
        // Persistence update applied via MemoryCRUD in the calling layer.
        // Context passed through to maintain actor isolation.
    }

    // MARK: - Simple embedding proxy

    /// Character frequency vector normalised to unit length.
    /// Replaced by real MLX embeddings in Phase 12.
    private func simpleEmbedding(from text: String) -> [Float] {
        var freq = [Float](repeating: 0, count: 26)
        for scalar in text.lowercased().unicodeScalars {
            let value = scalar.value
            if value >= 97, value <= 122 {
                freq[Int(value - 97)] += 1
            }
        }
        let magnitude = sqrt(freq.map { $0 * $0 }.reduce(0, +))
        guard magnitude > 0 else { return freq }
        return freq.map { $0 / magnitude }
    }
}
