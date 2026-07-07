import Foundation
import LocalAuthentication
import MnemoCore

/// Wraps LocalAuthentication for Face ID / Touch ID app lock.
/// Falls back to device passcode when biometrics are unavailable.
public final class BiometricAuthManager: Sendable {

    public init() {}

    public func canAuthenticate() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    public func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw MnemoError.securityError(error?.localizedDescription ?? "Device authentication is unavailable.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            ) { success, error in
                if let error {
                    continuation.resume(throwing: MnemoError.securityError(error.localizedDescription))
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
