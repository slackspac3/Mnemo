import Foundation
import MnemoCore
import Security

/// Wraps Security framework Keychain operations.
/// Stores keys with kSecAttrAccessibleWhenUnlockedThisDeviceOnly —
/// inaccessible when device is locked and non-migratable to another device.
public final class KeychainManager: Sendable {

    public init() {}

    public func store(_ data: Data, identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw MnemoError.securityError("Keychain store failed: \(status)")
        }
    }

    public func retrieve(identifier: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw MnemoError.securityError("Keychain retrieve failed: \(status)")
        }
        return data
    }

    public func delete(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw MnemoError.securityError("Keychain delete failed: \(status)")
        }
    }
}
