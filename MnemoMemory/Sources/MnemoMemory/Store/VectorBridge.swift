import Foundation
import MnemoCore

/// Actor-isolated interface to the vector store.
/// Phase 3: mock implementation returning empty/hardcoded results.
/// Phase 12: replace with live sqlite-vec implementation.
/// The interface is identical between mock and live — no other module changes.
public actor VectorBridge {

    public static let shared = VectorBridge()

    public init() {}

    /// Upsert an embedding for a memory record.
    public func upsert(id: UUID, embedding: [Float], summary: String) async throws {
        // Phase 3 mock: no-op
    }

    /// Semantic search — returns ordered UUIDs by relevance.
    /// Phase 3 mock: returns empty array.
    public func search(queryEmbedding: [Float], limit: Int) async throws -> [UUID] {
        return []
    }

    /// Semantic clustering for thread detection.
    /// Phase 3 mock: returns hardcoded empty groups for UI testing.
    public func cluster(limit: Int) async throws -> [[UUID]] {
        return []
    }

    /// Cross-modal corroboration query.
    /// Finds semantically similar memories from a different input source.
    /// Phase 3 mock: returns empty array.
    public func findCorroborating(
        embedding: [Float],
        excludingSource: InputSource,
        threshold: Float
    ) async throws -> [UUID] {
        return []
    }

    /// Delete a memory's embedding from the vector store.
    public func delete(id: UUID) async throws {
        // Phase 3 mock: no-op
    }
}
