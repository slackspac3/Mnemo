import Foundation
import MnemoCore
import MnemoMemory

/// Detects latent narrative threads in the memory corpus.
/// Runs as a background task on the BGAppRefreshTask schedule.
/// Proposes threads — never creates them automatically.
/// User must confirm, name, and describe each thread.
public final class ThreadDetectionEngine: Sendable {

    private let vectorBridge: VectorBridge
    public static let minimumMemoriesForThread = 3
    public static let minimumDaySpan = 2
    public static let confidenceThreshold = 0.70

    public init(vectorBridge: VectorBridge = .shared) {
        self.vectorBridge = vectorBridge
    }

    public func runDetection(
        allMemories: [MemorySnapshot]
    ) async throws -> [ThreadProposal] {
        let clusters = try await vectorBridge.cluster(limit: 20)

        var proposals: [ThreadProposal] = []

        for cluster in clusters {
            guard cluster.count >= Self.minimumMemoriesForThread else { continue }

            let clusterMemories = allMemories.filter { cluster.contains($0.id) }
            guard clusterMemories.count >= Self.minimumMemoriesForThread else { continue }

            let dates = clusterMemories.map { $0.createdAt }.sorted()
            guard let earliest = dates.first, let latest = dates.last else { continue }

            let daySpan = Calendar.current.dateComponents(
                [.day], from: earliest, to: latest
            ).day ?? 0

            guard daySpan >= Self.minimumDaySpan else { continue }

            let proposal = generateProposal(
                for: cluster,
                memories: clusterMemories,
                dateRange: earliest...latest
            )

            if proposal.confidence >= Self.confidenceThreshold {
                proposals.append(proposal)
            }
        }

        return proposals
    }

    private func generateProposal(
        for memoryIds: [UUID],
        memories: [MemorySnapshot],
        dateRange: ClosedRange<Date>
    ) -> ThreadProposal {
        // Phase 6: generate a name from the most common tags.
        // Phase 7: replace with LLM-generated name and description.
        let allTags = memories.flatMap { $0.tags }
        let tagFreq = Dictionary(allTags.map { ($0, 1) }, uniquingKeysWith: +)
        let topTag = tagFreq.max(by: { $0.value < $1.value })?.key ?? "memories"
        let name = topTag.capitalized + " Thread"

        return ThreadProposal(
            suggestedName: name,
            suggestedDescription: "A cluster of \(memories.count) related memories.",
            memoryIds: memoryIds,
            dateRange: dateRange,
            confidence: 0.72
        )
    }
}
