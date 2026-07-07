import Foundation

/// Pure Settings decision policy for App Lock preference changes.
/// This keeps LocalAuthentication outside unit tests while preserving the app's
/// local-only gate semantics.
public struct AppLockSettingsPolicy: Sendable {

    public enum Decision: Equatable, Sendable {
        case unchanged
        case authenticateToEnable
        case authenticateToDisable
        case blockEnableUnavailable
        case allowDisableUnavailable
    }

    public init() {}

    public func decision(
        requestedEnabled: Bool,
        currentEnabled: Bool,
        authenticationAvailable: Bool
    ) -> Decision {
        guard requestedEnabled != currentEnabled else { return .unchanged }

        guard authenticationAvailable else {
            return requestedEnabled ? .blockEnableUnavailable : .allowDisableUnavailable
        }

        return requestedEnabled ? .authenticateToEnable : .authenticateToDisable
    }
}
