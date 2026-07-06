import Foundation
import MnemoCore
import MnemoMemory

/// Computes and updates Persistence Scores for memory records.
/// Uses four weighted signals specific to personal knowledge management.
/// This is Patent Candidate 2 — the User-Calibrated Knowledge Persistence Model.
///
/// Four signals:
/// 1. Intentionality weight — explicit confirmation vs auto-extraction
/// 2. Retrieval recency — log-scaled recency of last recall
/// 3. Cross-modal corroboration — count of corroborating evidence
/// 4. User override history — highest-weighted signal
public final class PersistenceEngine: Sendable {

    // MARK: - Signal weights

    private static let intentionalityWeight: Double = 0.25
    private static let retrievalRecencyWeight: Double = 0.20
    private static let corroborationWeight: Double = 0.25
    private static let overrideWeight: Double = 0.30

    // MARK: - Thresholds

    public static let activeThreshold: Double = 0.50
    public static let dormantThreshold: Double = 0.25

    public init() {}

    /// Compute a fresh Persistence Score for a memory record.
    public func computeScore(for record: MemoryRecord) -> Double {
        let intentionality = intentionalitySignal(record: record)
        let recency = retrievalRecencySignal(record: record)
        let corroboration = corroborationSignal(record: record)
        let override = overrideSignal(record: record)

        let score = (intentionality * Self.intentionalityWeight)
            + (recency * Self.retrievalRecencyWeight)
            + (corroboration * Self.corroborationWeight)
            + (override * Self.overrideWeight)

        return max(0.0, min(1.0, score))
    }

    /// Derive the PersistenceState from a score.
    public func persistenceState(from score: Double) -> PersistenceState {
        switch score {
        case Self.activeThreshold...:
            return .active
        case Self.dormantThreshold..<Self.activeThreshold:
            return .dormant
        default:
            return .review
        }
    }

    /// Batch evaluate all records and return update actions.
    public func evaluateAll(records: [MemoryRecord]) -> [PersistenceUpdate] {
        records.map { record in
            let score = computeScore(for: record)
            let state = persistenceState(from: score)
            return PersistenceUpdate(
                memoryId: record.id,
                newScore: score,
                newState: state
            )
        }
    }

    // MARK: - Signal computations

    private func intentionalitySignal(record: MemoryRecord) -> Double {
        // Memories with higher initial confidence were more deliberately captured
        return record.confidence
    }

    private func retrievalRecencySignal(record: MemoryRecord) -> Double {
        // Decays logarithmically with days since last update
        let daysSinceUpdate = Calendar.current.dateComponents(
            [.day],
            from: record.updatedAt,
            to: Date()
        ).day ?? 0

        guard daysSinceUpdate > 0 else { return 1.0 }
        return max(0.0, 1.0 - log(Double(daysSinceUpdate) + 1) / log(365))
    }

    private func corroborationSignal(record: MemoryRecord) -> Double {
        // Each corroborating source adds 0.15, capped at 0.45 (3 sources)
        let count = Double(record.corroboratingEvidenceIds.count)
        return min(0.45, count * 0.15)
    }

    private func overrideSignal(record: MemoryRecord) -> Double {
        // If the user has manually marked this done, persistence drops
        if record.isDone { return 0.0 }
        // Base signal from confidence — override history tracked via ProvenanceChain
        return record.confidence * 0.8
    }
}

public struct PersistenceUpdate: Sendable {
    public let memoryId: UUID
    public let newScore: Double
    public let newState: PersistenceState

    public init(memoryId: UUID, newScore: Double, newState: PersistenceState) {
        self.memoryId = memoryId
        self.newScore = newScore
        self.newState = newState
    }
}
