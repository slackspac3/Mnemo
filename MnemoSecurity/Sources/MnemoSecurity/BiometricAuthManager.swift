import Foundation
import LocalAuthentication
import MnemoCore

/// Wraps LocalAuthentication for Face ID / Touch ID app lock.
/// Falls back to device passcode when biometrics are unavailable.
public final class BiometricAuthManager: Sendable {

    public init() {}

    public func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to device passcode
            return try await authenticateWithPasscode(reason: reason, context: context)
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
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

    private func authenticateWithPasscode(reason: String, context: LAContext) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
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
