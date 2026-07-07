import Foundation
import MnemoCore

/// Applies NSFileProtectionComplete to files on disk.
/// Files with this protection class are inaccessible when the device is locked,
/// even to forensic extraction tools.
public final class FileProtectionManager: Sendable {

    public init() {}

    public func apply(to url: URL) throws {
        #if os(iOS)
        do {
            try (url as NSURL).setResourceValue(
                URLFileProtection.complete,
                forKey: .fileProtectionKey
            )
        } catch {
            throw MnemoError.securityError("File protection application failed: \(error.localizedDescription)")
        }
        #else
        _ = url
        #endif
    }
}
