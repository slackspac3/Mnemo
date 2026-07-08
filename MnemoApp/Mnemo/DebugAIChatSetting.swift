#if DEBUG
import Foundation

enum DebugAIChatSetting {
    static let userDefaultsKey = "mnemo.debugLocalAIChatEnabled"

    static var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }
}
#endif
