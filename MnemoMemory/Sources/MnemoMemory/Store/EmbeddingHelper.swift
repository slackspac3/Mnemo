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
    public static let dimensions = CharacterFrequencyEmbeddingProvider.dimensions

    public let providerDescriptor: EmbeddingProviderDescriptor
    private let provider: any EmbeddingProvider

    public init(provider: any EmbeddingProvider = CharacterFrequencyEmbeddingProvider()) {
        self.provider = provider
        self.providerDescriptor = provider.descriptor
    }

    /// Generate an embedding for a text string.
    /// Returns a normalised 26-dimensional character frequency vector.
    public func embed(_ text: String) -> [Float] {
        (try? embedStrict(text)) ?? []
    }

    /// Generate an embedding and surface provider failures.
    public func embedStrict(_ text: String) throws -> [Float] {
        let embedding = try provider.embed(text)
        guard embedding.count == providerDescriptor.dimensions else {
            throw EmbeddingProviderError.dimensionMismatch(
                expected: providerDescriptor.dimensions,
                actual: embedding.count
            )
        }
        return embedding
    }

    /// Upsert a memory's embedding into the VectorBridge.
    public func index(id: UUID, summary: String) async throws {
        let embedding = try embedStrict(summary)
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
            let embedding = try embedStrict(snapshot.summary)
            try await VectorBridge.shared.upsert(
                id: snapshot.id,
                embedding: embedding,
                summary: snapshot.summary
            )
        }
    }
}
