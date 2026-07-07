import Foundation
import MnemoCore

/// Central security facade. All Keychain, Secure Enclave, device authentication,
/// file protection, and secure deletion operations go through this type.
/// No other module touches security APIs directly.
public final class SecurityLayer: Sendable {

    public static let shared = SecurityLayer()

    private let keychain: KeychainManager
    private let secureEnclave: SecureEnclaveManager
    private let biometric: BiometricAuthManager
    private let fileProtection: FileProtectionManager
    private let secureDeletion: SecureDeletionManager

    public init(
        keychain: KeychainManager = KeychainManager(),
        secureEnclave: SecureEnclaveManager = SecureEnclaveManager(),
        biometric: BiometricAuthManager = BiometricAuthManager(),
        fileProtection: FileProtectionManager = FileProtectionManager(),
        secureDeletion: SecureDeletionManager = SecureDeletionManager()
    ) {
        self.keychain = keychain
        self.secureEnclave = secureEnclave
        self.biometric = biometric
        self.fileProtection = fileProtection
        self.secureDeletion = secureDeletion
    }

    // MARK: - Keychain

    public func storeKey(_ key: Data, identifier: String) throws {
        try keychain.store(key, identifier: identifier)
    }

    public func retrieveKey(identifier: String) throws -> Data {
        try keychain.retrieve(identifier: identifier)
    }

    public func deleteKey(identifier: String) throws {
        try keychain.delete(identifier: identifier)
    }

    // MARK: - Secure Enclave

    public func generateSecureEnclaveKey(identifier: String) throws {
        try secureEnclave.generateKey(identifier: identifier)
    }

    public func revokeSecureEnclaveKey(identifier: String) throws {
        try secureEnclave.revokeKey(identifier: identifier)
    }

    // MARK: - Device Authentication

    public func canAuthenticateWithBiometrics() -> Bool {
        biometric.canAuthenticate()
    }

    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        try await biometric.authenticate(reason: reason)
    }

    // MARK: - File Protection

    public func applyFileProtection(to url: URL) throws {
        try fileProtection.apply(to: url)
    }

    // MARK: - Secure Deletion

    public func secureDelete(fileURL: URL) throws {
        try secureDeletion.delete(fileURL: fileURL)
    }

    public func secureWipeDatabase(at path: String) throws {
        try secureDeletion.wipeDatabase(at: path)
    }
}
