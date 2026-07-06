import Testing
import Foundation
@testable import MnemoSecurity

@Suite("MnemoSecurity")
struct MnemoSecurityTests {

    @Test("SecurityLayer shared instance is accessible")
    func sharedInstance() {
        let layer = SecurityLayer.shared
        #expect(layer === SecurityLayer.shared)
    }

    @Test("KeychainManager store and retrieve round trip")
    func keychainRoundTrip() throws {
        let manager = KeychainManager()
        let testData = "test-key-data".data(using: .utf8)!
        let identifier = "com.mnemo.test.\(UUID().uuidString)"

        try manager.store(testData, identifier: identifier)
        let retrieved = try manager.retrieve(identifier: identifier)
        #expect(retrieved == testData)

        // Cleanup
        try manager.delete(identifier: identifier)
    }

    @Test("KeychainManager delete removes item")
    func keychainDelete() throws {
        let manager = KeychainManager()
        let testData = "delete-test".data(using: .utf8)!
        let identifier = "com.mnemo.delete.\(UUID().uuidString)"

        try manager.store(testData, identifier: identifier)
        try manager.delete(identifier: identifier)

        #expect(throws: (any Error).self) {
            try manager.retrieve(identifier: identifier)
        }
    }

    @Test("FileProtectionManager applies protection without throwing on valid URL")
    func fileProtectionApplied() throws {
        let manager = FileProtectionManager()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        try manager.apply(to: tempURL)
    }

    @Test("SecureDeletionManager deletes file and leaves no trace")
    func secureDeletion() throws {
        let manager = SecureDeletionManager()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try "sensitive data".write(to: tempURL, atomically: true, encoding: .utf8)
        try manager.delete(fileURL: tempURL)
        #expect(!FileManager.default.fileExists(atPath: tempURL.path))
    }
}
