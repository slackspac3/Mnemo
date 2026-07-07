import Testing
import Foundation
import SwiftData
@testable import MnemoMemory
import MnemoCore

@Suite("VectorBridge - Live", .serialized)
struct VectorBridgeTests {

    @Test("VectorBridge opens without error")
    func vectorBridgeOpens() async throws {
        let bridge = VectorBridge()
        try await bridge.open()
    }

    @Test("VectorBridge test storage uses temporary path")
    func vectorBridgeUsesTemporaryPathInTests() async {
        let bridge = VectorBridge()
        let path = await bridge.diagnosticsDatabasePath()
        #expect(path.hasPrefix(FileManager.default.temporaryDirectory.path))
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

    @Test("MemoryCRUD insertAndIndex makes a saved memory searchable")
    @MainActor
    func insertAndIndexSearchable() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let summary = "Waterfall I loved in Guam"
        let record = MemoryRecord(
            rawInput: summary,
            summary: summary,
            memoryType: .preference,
            inputSource: .image,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.95
        )

        try await MemoryCRUD.insertAndIndex(record, into: context)

        let queryEmbedding = EmbeddingHelper().embed("waterfall guam")
        let results = try await VectorBridge.shared.search(
            queryEmbedding: queryEmbedding,
            limit: 5
        )
        #expect(results.contains(record.id))

        try await VectorBridge.shared.delete(id: record.id)
    }

    @Test("MemoryCRUD deletePermanently removes SwiftData record and vector row")
    @MainActor
    func deletePermanentlyRemovesRecordAndIndex() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let summary = "Mum wears size 38 shoes"
        let record = MemoryRecord(
            rawInput: summary,
            summary: summary,
            memoryType: .fact,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.95
        )

        try await MemoryCRUD.insertAndIndex(record, into: context)
        let queryEmbedding = EmbeddingHelper().embed("mum size shoes")
        let beforeDelete = try await VectorBridge.shared.search(
            queryEmbedding: queryEmbedding,
            limit: 5
        )
        #expect(beforeDelete.contains(record.id))

        try await MemoryCRUD.deletePermanently(id: record.id, in: context)

        let fetched = try MemoryCRUD.fetch(id: record.id, in: context)
        let afterDelete = try await VectorBridge.shared.search(
            queryEmbedding: queryEmbedding,
            limit: 5
        )
        #expect(fetched == nil)
        #expect(!afterDelete.contains(record.id))
    }

    @Test("MemoryCRUD rebuildIndex makes existing SwiftData memories searchable")
    @MainActor
    func rebuildIndexSearchable() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let first = MemoryRecord(
            rawInput: "The Guam waterfall I liked was Tarzan Falls",
            summary: "The Guam waterfall I liked was Tarzan Falls",
            memoryType: .preference,
            inputSource: .image,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.90
        )
        let second = MemoryRecord(
            rawInput: "Ahmed prefers quiet restaurants",
            summary: "Ahmed prefers quiet restaurants",
            memoryType: .preference,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.90
        )

        try MemoryCRUD.insert(first, into: context)
        try MemoryCRUD.insert(second, into: context)
        try await MemoryCRUD.rebuildIndex(in: context)

        let waterfallResults = try await VectorBridge.shared.search(
            queryEmbedding: EmbeddingHelper().embed("waterfall guam"),
            limit: 5
        )
        let restaurantResults = try await VectorBridge.shared.search(
            queryEmbedding: EmbeddingHelper().embed("ahmed quiet restaurants"),
            limit: 5
        )

        #expect(waterfallResults.contains(first.id))
        #expect(restaurantResults.contains(second.id))

        try await MemoryCRUD.deletePermanently(id: first.id, in: context)
        try await MemoryCRUD.deletePermanently(id: second.id, in: context)
    }

    @Test("MemoryCRUD archiveAndUnindex hides memory and removes vector row")
    @MainActor
    func archiveAndUnindexRemovesVectorRow() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord("Mum wears size 38 shoes")

        try await MemoryCRUD.insertAndIndex(record, into: context)
        let queryEmbedding = EmbeddingHelper().embed("mum size shoes")
        let beforeArchive = try await VectorBridge.shared.search(
            queryEmbedding: queryEmbedding,
            limit: 5
        )
        #expect(beforeArchive.contains(record.id))

        try await MemoryCRUD.archiveAndUnindex(id: record.id, in: context)

        let visibleRecords = try MemoryCRUD.fetchAll(in: context)
        let allRecords = try MemoryCRUD.fetchAll(in: context, includeArchived: true)
        let afterArchive = try await VectorBridge.shared.search(
            queryEmbedding: queryEmbedding,
            limit: 5
        )

        #expect(visibleRecords.isEmpty)
        #expect(allRecords.first?.isArchived == true)
        #expect(!afterArchive.contains(record.id))
    }

    @Test("MemoryCRUD rebuildIndex purges stale and archived vector rows")
    @MainActor
    func rebuildIndexPurgesStaleRows() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let active = Self.makeRecord("Ahmed prefers quiet restaurants")
        let archived = Self.makeRecord("Mum wears size 38 shoes")
        let orphanId = UUID()

        try MemoryCRUD.insert(active, into: context)
        try MemoryCRUD.insert(archived, into: context)
        try await VectorBridge.shared.upsert(
            id: orphanId,
            embedding: EmbeddingHelper().embed("orphan passport"),
            summary: "orphan passport"
        )
        try await VectorBridge.shared.upsert(
            id: archived.id,
            embedding: EmbeddingHelper().embed(archived.summary),
            summary: archived.summary
        )
        try await MemoryCRUD.archiveAndUnindex(id: archived.id, in: context)

        try await MemoryCRUD.rebuildIndex(in: context)

        let restaurantResults = try await VectorBridge.shared.search(
            queryEmbedding: EmbeddingHelper().embed("ahmed quiet restaurants"),
            limit: 5
        )
        let archivedResults = try await VectorBridge.shared.search(
            queryEmbedding: EmbeddingHelper().embed("mum size shoes"),
            limit: 10
        )
        let orphanResults = try await VectorBridge.shared.search(
            queryEmbedding: EmbeddingHelper().embed("orphan passport"),
            limit: 10
        )

        #expect(restaurantResults.contains(active.id))
        #expect(!archivedResults.contains(archived.id))
        #expect(!orphanResults.contains(orphanId))
    }

    @Test("MemoryCRUD deletePermanently removes orphan vector row")
    @MainActor
    func deletePermanentlyRemovesOrphanVectorRow() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let orphanId = UUID()
        let embedding = EmbeddingHelper().embed("orphan gym locker code")

        try await VectorBridge.shared.upsert(
            id: orphanId,
            embedding: embedding,
            summary: "orphan gym locker code"
        )
        let beforeDelete = try await VectorBridge.shared.search(queryEmbedding: embedding, limit: 5)
        #expect(beforeDelete.contains(orphanId))

        try await MemoryCRUD.deletePermanently(id: orphanId, in: context)

        let afterDelete = try await VectorBridge.shared.search(queryEmbedding: embedding, limit: 5)
        #expect(!afterDelete.contains(orphanId))
    }

    @Test("VectorBridge wipe removes all rows")
    func wipeRemovesRows() async throws {
        let bridge = VectorBridge()
        try await bridge.open()
        let first = UUID()
        let second = UUID()
        let embedding = EmbeddingHelper().embed("wipe test row")

        try await bridge.upsert(id: first, embedding: embedding, summary: "wipe test row one")
        try await bridge.upsert(id: second, embedding: embedding, summary: "wipe test row two")
        try await bridge.wipe()

        let results = try await bridge.search(queryEmbedding: embedding, limit: 10)
        #expect(!results.contains(first))
        #expect(!results.contains(second))
    }

    private static func makeRecord(_ summary: String) -> MemoryRecord {
        MemoryRecord(
            rawInput: summary,
            summary: summary,
            memoryType: .fact,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.95
        )
    }
}
