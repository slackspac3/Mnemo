import Foundation
import MnemoCore
import Security

/// Manages keys generated in the iOS Secure Enclave.
/// Secure Enclave keys are non-exportable — they cannot be extracted
/// from the device under any circumstances.
public final class SecureEnclaveManager: Sendable {

    public init() {}

    public func generateKey(identifier: String) throws {
        var error: Unmanaged<CFError>?

        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage],
            &error
        ) else {
            throw MnemoError.securityError("SecAccessControl creation failed")
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: identifier.data(using: .utf8)!,
                kSecAttrAccessControl as String: access,
            ],
        ]

        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            throw MnemoError.securityError("Secure Enclave key generation failed")
        }
    }

    public func revokeKey(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: identifier.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw MnemoError.securityError("Secure Enclave key revocation failed: \(status)")
        }
    }
}
