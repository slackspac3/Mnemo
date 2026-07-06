import Foundation
import MnemoCore
import MnemoMemory

/// Generates conversational observations from the UserModel.
/// Runs entirely on-device. No new permissions required.
/// Part of the Mnemo Sense paid tier.
public final class PatternInsightsEngine: Sendable {

    public init() {}

    public func generateInsights(
        userModel: UserModel,
        memories: [MemorySnapshot]
    ) -> [PatternInsight] {
        var insights: [PatternInsight] = []

        // High-frequency recall patterns
        if let recallInsight = checkHighFrequencyRecall(userModel: userModel, memories: memories) {
            insights.append(recallInsight)
        }

        // Unused memories
        if let unusedInsight = checkUnusedMemories(memories: memories) {
            insights.append(unusedInsight)
        }

        return insights
    }

    private func checkHighFrequencyRecall(
        userModel: UserModel,
        memories: [MemorySnapshot]
    ) -> PatternInsight? {
        let freq = (try? JSONDecoder().decode(
            [String: Int].self, from: userModel.recallFrequency
        )) ?? [:]

        guard let topEntry = freq.max(by: { $0.value < $1.value }),
              topEntry.value >= 3,
              let topId = UUID(uuidString: topEntry.key),
              let memory = memories.first(where: { $0.id == topId })
        else { return nil }

        return PatternInsight(
            text: "You've looked up '\(memory.summary.prefix(40))' \(topEntry.value) times recently.",
            relatedMemoryIds: [topId]
        )
    }

    private func checkUnusedMemories(memories: [MemorySnapshot]) -> PatternInsight? {
        let dormant = memories.filter { $0.persistenceState == .review }
        guard dormant.count >= 3 else { return nil }

        return PatternInsight(
            text: "You have \(dormant.count) memories that haven't been used recently. Want to review them?",
            relatedMemoryIds: dormant.map { $0.id }
        )
    }
}

public struct PatternInsight: Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let relatedMemoryIds: [UUID]
    public let generatedAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        relatedMemoryIds: [UUID] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.relatedMemoryIds = relatedMemoryIds
        self.generatedAt = generatedAt
    }
}
