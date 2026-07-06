import Foundation
import MnemoCore

/// Generates embeddings for memory text.
/// Phase 12: deterministic character-frequency embedding (26-dimensional).
/// This is a quality placeholder -- semantically meaningful enough for
/// basic clustering and corroboration, but not as accurate as a real
/// sentence embedding model.
///
/// Replacement path:
/// 1. Add MLX Swift dependency when On-Demand Resources are configured
/// 2. Load all-MiniLM-L6-v2 MLX model
/// 3. Replace characterFrequencyEmbedding() with mlxEmbedding()
/// 4. Re-index existing memories via a migration task on first launch
public struct EmbeddingHelper: Sendable {

    public static let shared = EmbeddingHelper()
    public static let dimensions = 26

    public init() {}

    /// Generate an embedding for a text string.
    /// Returns a normalised 26-dimensional character frequency vector.
    public func embed(_ text: String) -> [Float] {
        characterFrequencyEmbedding(from: text)
    }

    /// Upsert a memory's embedding into the VectorBridge.
    public func index(id: UUID, summary: String) async throws {
        let embedding = embed(summary)
        try await VectorBridge.shared.upsert(
            id: id,
            embedding: embedding,
            summary: summary
        )
    }

    /// Re-index a batch of memory snapshots.
    /// Called after restore to rebuild the vector index from SwiftData records.
    public func reindex(snapshots: [MemorySnapshot]) async throws {
        for snapshot in snapshots {
            let embedding = embed(snapshot.summary)
            try await VectorBridge.shared.upsert(
                id: snapshot.id,
                embedding: embedding,
                summary: snapshot.summary
            )
        }
    }

    // MARK: - Embedding implementations

    /// Character frequency vector normalised to unit length.
    /// Maps each lowercase letter a-z to a dimension.
    private func characterFrequencyEmbedding(from text: String) -> [Float] {
        var freq = [Float](repeating: 0, count: Self.dimensions)
        let lower = text.lowercased()

        for char in lower {
            if let ascii = char.asciiValue {
                let idx = Int(ascii) - Int(Character("a").asciiValue!)
                if idx >= 0, idx < Self.dimensions {
                    freq[idx] += 1
                }
            }
        }

        let magnitude = sqrt(freq.map { $0 * $0 }.reduce(0, +))
        guard magnitude > 0 else { return freq }
        return freq.map { $0 / magnitude }
    }
}
