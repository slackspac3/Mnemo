#if DEBUG
import Foundation

enum DebugAIChatSetting {
    static let deterministicOnlyUserDefaultsKey = "mnemo.debugDeterministicChatOnly"

    /// DEBUG builds use Local AI as the primary Chat path by default.
    /// This override exists only to compare the deterministic fallback path.
    static var usesLocalAIFirst: Bool {
        get {
            !UserDefaults.standard.bool(forKey: deterministicOnlyUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(!newValue, forKey: deterministicOnlyUserDefaultsKey)
        }
    }

    static var usesDeterministicOnly: Bool {
        get {
            !usesLocalAIFirst
        }
        set {
            usesLocalAIFirst = !newValue
        }
    }
}

@MainActor
enum DebugLocalAIBackfillState {
    static let userDefaultsKey = "mnemo.debugLocalAIChatBackfillComplete"

    private struct InFlightBackfill {
        let id: UUID
        let task: Task<Void, Error>
    }

    private static var inFlightBackfill: InFlightBackfill?

    static var isComplete: Bool {
        get {
            UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }

    static func ensureComplete(
        using operation: @escaping @MainActor () async throws -> Void
    ) async throws {
        guard !isComplete else { return }

        if let inFlightBackfill {
            try await finish(inFlightBackfill)
            return
        }

        let backfill = InFlightBackfill(
            id: UUID(),
            task: Task { @MainActor in
                try await operation()
            }
        )
        inFlightBackfill = backfill
        try await finish(backfill)
    }

    static func rebuild(
        using operation: @escaping @MainActor () async throws -> Void
    ) async throws {
        if let inFlightBackfill {
            try? await finish(inFlightBackfill)
        }
        isComplete = false
        try await ensureComplete(using: operation)
    }

    static func prepareForReset() async {
        if let inFlightBackfill {
            try? await finish(inFlightBackfill)
        }
        isComplete = false
    }

    private static func finish(_ backfill: InFlightBackfill) async throws {
        do {
            try await backfill.task.value
            if inFlightBackfill?.id == backfill.id {
                inFlightBackfill = nil
                isComplete = true
            }
        } catch {
            if inFlightBackfill?.id == backfill.id {
                inFlightBackfill = nil
                isComplete = false
            }
            throw error
        }
    }
}
#endif
