import Foundation
import MnemoMemory

/// Prototype wrapper for the future AI-led recall pipeline.
///
/// This scaffold intentionally does not generate answers with MLX or Foundation
/// Models yet. It preserves the current source-grounded deterministic recall
/// behavior until flags, device capability, model assets, and validation all
/// permit the AI path.
public struct AIRecallPipeline {
    public let flags: AICoreFlags
    private let deterministicRecall: RecallEngine

    public init(
        flags: AICoreFlags = .testFlightDefault,
        deterministicRecall: RecallEngine = RecallEngine()
    ) {
        self.flags = flags
        self.deterministicRecall = deterministicRecall
    }

    @MainActor
    public func recall(query: String, memories: [MemoryRecord]) async -> RecallResult {
        guard flags.aiCoreEnabled,
              flags.hasModelBackedPathEnabled
        else {
            return fallbackRecall(query: query, memories: memories)
        }

        // Future implementation:
        // 1. Embed the query locally.
        // 2. Retrieve semantic candidates from the local vector store.
        // 3. Rerank with deterministic safety guards.
        // 4. Compose an answer from retrieved memories only.
        // 5. Validate cited IDs before returning.
        return fallbackRecall(query: query, memories: memories)
    }

    @MainActor
    private func fallbackRecall(query: String, memories: [MemoryRecord]) -> RecallResult {
        guard flags.deterministicRecallFallbackEnabled else {
            return RecallResult(
                text: "AI recall is not available in this build.",
                citedMemoryIds: [],
                citations: []
            )
        }

        return deterministicRecall.recall(query: query, memories: memories)
    }
}
