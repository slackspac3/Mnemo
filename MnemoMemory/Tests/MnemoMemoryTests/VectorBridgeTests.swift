import Testing
import Foundation
@testable import MnemoMemory
import MnemoCore

@Suite("VectorBridge - Live")
struct VectorBridgeTests {

    @Test("VectorBridge opens without error")
    func vectorBridgeOpens() async throws {
        let bridge = VectorBridge()
        try await bridge.open()
    }

    @Test("VectorBridge upsert and search round trip")
    func upsertAndSearch() async throws {
        let bridge = VectorBridge()
        try await bridge.open()

        let id = UUID()
        let embedding: [Float] = [Float](repeating: 0, count: 26).enumerated().map { i, _ in
            i == 0 ? 1.0 : 0.0
        }
        try await bridge.upsert(id: id, embedding: embedding, summary: "Test memory")

        let results = try await bridge.search(queryEmbedding: embedding, limit: 5)
        #expect(results.contains(id))

        try await bridge.delete(id: id)
    }

    @Test("VectorBridge delete removes record")
    func deleteRemovesRecord() async throws {
        let bridge = VectorBridge()
        try await bridge.open()

        let id = UUID()
        let embedding: [Float] = (0..<26).map { Float($0) / 26.0 }
        try await bridge.upsert(id: id, embedding: embedding, summary: "Delete test")
        try await bridge.delete(id: id)

        let results = try await bridge.search(queryEmbedding: embedding, limit: 10)
        #expect(!results.contains(id))
    }

    @Test("EmbeddingHelper produces normalised vector")
    func embeddingNormalised() {
        let helper = EmbeddingHelper()
        let embedding = helper.embed("clothing size medium zara")
        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        #expect(abs(magnitude - 1.0) < 0.001 || magnitude == 0.0)
    }

    @Test("EmbeddingHelper similar texts have higher similarity than dissimilar")
    func embeddingSemanticOrdering() {
        let helper = EmbeddingHelper()
        let base = helper.embed("clothing size medium")
        let similar = helper.embed("clothes size large")
        let dissimilar = helper.embed("passport number expiry date")

        func cosine(_ a: [Float], _ b: [Float]) -> Float {
            let dot = zip(a, b).map(*).reduce(0, +)
            let magA = sqrt(a.map { $0 * $0 }.reduce(0, +))
            let magB = sqrt(b.map { $0 * $0 }.reduce(0, +))
            guard magA > 0, magB > 0 else { return 0 }
            return dot / (magA * magB)
        }

        let simScore = cosine(base, similar)
        let dissimScore = cosine(base, dissimilar)
        #expect(simScore > dissimScore)
    }
}
