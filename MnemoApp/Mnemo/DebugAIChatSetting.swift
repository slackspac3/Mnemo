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

enum DebugLocalAIBackfillState {
    static let userDefaultsKey = "mnemo.debugLocalAIChatBackfillComplete"

    static var isComplete: Bool {
        get {
            UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }
}
#endif
