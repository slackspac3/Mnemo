import Foundation

/// Small deterministic policy for deciding when the local UI lock should engage.
/// App Lock is a local access gate; it does not create accounts or store biometrics.
public struct AppLockPolicy: Sendable {
    public let backgroundGracePeriod: TimeInterval

    public init(backgroundGracePeriod: TimeInterval = 0) {
        self.backgroundGracePeriod = backgroundGracePeriod
    }

    public func shouldLockOnLaunch(appLockEnabled: Bool, onboardingComplete: Bool) -> Bool {
        appLockEnabled && onboardingComplete
    }

    public func shouldLockAfterBackground(
        appLockEnabled: Bool,
        onboardingComplete: Bool,
        backgroundedAt: Date?,
        now: Date = Date()
    ) -> Bool {
        guard appLockEnabled, onboardingComplete else { return false }
        guard let backgroundedAt else { return true }
        return now.timeIntervalSince(backgroundedAt) >= backgroundGracePeriod
    }
}
