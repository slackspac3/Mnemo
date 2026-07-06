import Foundation
import MnemoCore
import MnemoMemory

/// Selects one memory per week to surface as a Memory Moment.
/// Scheduled via BGAppRefreshTask. Opt-in only.
/// Selection criteria: not recently recalled, persistent or timeBound,
/// not previously surfaced as a moment in last 90 days, highest confidence.
public final class MemoryMomentsEngine: Sendable {

    public init() {}

    public func selectMoment(from records: [MemoryRecord]) -> MemoryRecord? {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now

        return records
            .filter { record in
                guard !record.isArchived && !record.isDone else { return false }
                guard record.decayClassEnum != .session else { return false }
                guard record.updatedAt < thirtyDaysAgo else { return false }
                return true
            }
            .max(by: { $0.confidence < $1.confidence })
    }
}

extension MemoryRecord {
    var decayClassEnum: DecayClass? {
        // Derive decay class from persistence state as a proxy.
        switch persistenceStateEnum {
        case .active:
            return .persistent
        case .dormant:
            return .timeBound
        case .review:
            return .session
        case .none:
            return nil
        }
    }
}
