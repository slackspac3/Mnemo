import Testing
import Foundation
@testable import MnemoMemory
import MnemoCore

@Suite("Efficiency Baseline", .serialized)
struct EfficiencyBaselineTests {

    @Test("RecallEngine latency stays within local baseline thresholds")
    @MainActor
    func recallEngineLatencyBaseline() {
        let engine = RecallEngine()
        let queries = [
            "What size does mum wear?",
            "Which waterfall did I like in Guam?",
            "What does Ahmed prefer?",
            "What skincare did the dermatologist recommend?",
            "Where did I park at Dubai Mall?",
            "What is my passport number?",
        ]

        for count in [30, 100, 500, 1_000] {
            let memories = syntheticMemories(count: count)
            _ = engine.recall(query: queries[0], memories: memories)

            let timings = queries.map { query in
                measureMilliseconds {
                    _ = engine.recall(query: query, memories: memories)
                }
            }
            let metrics = BaselineMetrics(timings)

            print("EfficiencyBaseline recall count=\(count) avg=\(metrics.average)ms p95=\(metrics.p95)ms max=\(metrics.max)ms")
            #expect(metrics.p95 < 750.0)
            #expect(metrics.max < 1_500.0)
        }
    }

    @Test("VectorBridge operations stay within local baseline thresholds")
    func vectorBridgeLatencyBaseline() async throws {
        for count in [30, 100, 500, 1_000] {
            let bridge = VectorBridge(databaseURL: temporaryVectorURL(name: "baseline-\(count)"))
            let records = syntheticMemorySummaries(count: count)

            let upsertMilliseconds = try await measureAsyncMilliseconds {
                for record in records {
                    try await bridge.upsert(
                        id: record.id,
                        embedding: EmbeddingHelper().embed(record.summary),
                        summary: record.summary
                    )
                }
            }

            var searchTimings: [Double] = []
            for record in records.prefix(10) {
                let timing = try await measureAsyncMilliseconds {
                    _ = try await bridge.search(
                        queryEmbedding: EmbeddingHelper().embed(record.summary),
                        limit: 5
                    )
                }
                searchTimings.append(timing)
            }
            let searchMetrics = BaselineMetrics(searchTimings)

            let deleteTarget = records[count / 2]
            let deleteMilliseconds = try await measureAsyncMilliseconds {
                try await bridge.delete(id: deleteTarget.id)
            }

            let wipeMilliseconds = try await measureAsyncMilliseconds {
                try await bridge.wipe()
            }

            print(
                "EfficiencyBaseline vector count=\(count) upsert=\(upsertMilliseconds)ms searchAvg=\(searchMetrics.average)ms searchMax=\(searchMetrics.max)ms delete=\(deleteMilliseconds)ms wipe=\(wipeMilliseconds)ms"
            )
            #expect(upsertMilliseconds < 10_000.0)
            #expect(searchMetrics.max < 500.0)
            #expect(deleteMilliseconds < 1_000.0)
            #expect(wipeMilliseconds < 1_000.0)
        }
    }

    @MainActor
    private func syntheticMemories(count: Int) -> [MemoryRecord] {
        var memories = ManualRecallFixture.makeMemories()
        if count <= memories.count {
            return Array(memories.prefix(count))
        }

        let additionalCount = count - memories.count
        memories.append(contentsOf: (0..<additionalCount).map { index in
            let text = "Synthetic memory \(index): project note \(index) for baseline recall testing."
            return MemoryRecord(
                id: UUID(),
                rawInput: text,
                summary: text,
                memoryType: .fact,
                persistenceScore: 0.50,
                inputSource: .text,
                processingTier: .onDevice,
                modalityThresholdUsed: 0.90,
                confidence: 0.80,
                createdAt: ManualRecallFixture.referenceDate.addingTimeInterval(TimeInterval(10_000 + index)),
                updatedAt: ManualRecallFixture.referenceDate.addingTimeInterval(TimeInterval(10_000 + index))
            )
        })
        return memories
    }

    private func syntheticMemorySummaries(count: Int) -> [(id: UUID, summary: String)] {
        (0..<count).map { index in
            (
                id: UUID(),
                summary: "Vector baseline memory \(index) about topic \(index % 17) and detail \(index % 31)."
            )
        }
    }

    private func temporaryVectorURL(name: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("mnemo-\(name)-\(UUID().uuidString).sqlite")
    }

    private func measureMilliseconds(_ operation: () -> Void) -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        operation()
        let end = DispatchTime.now().uptimeNanoseconds
        return Double(end - start) / 1_000_000.0
    }

    private func measureAsyncMilliseconds(_ operation: () async throws -> Void) async throws -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        try await operation()
        let end = DispatchTime.now().uptimeNanoseconds
        return Double(end - start) / 1_000_000.0
    }

    private struct BaselineMetrics {
        let average: Double
        let p95: Double
        let max: Double

        init(_ values: [Double]) {
            let sorted = values.sorted()
            self.average = values.reduce(0, +) / Double(Swift.max(values.count, 1))
            self.max = sorted.last ?? 0
            let index = min(sorted.count - 1, Int(Double(sorted.count - 1) * 0.95))
            self.p95 = sorted.isEmpty ? 0 : sorted[index]
        }
    }
}
