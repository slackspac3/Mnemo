import Foundation
import MnemoCore

/// Handles secure deletion of files and databases.
/// Simply removing a file reference is insufficient — data must be
/// overwritten before deletion so it cannot be recovered forensically.
public final class SecureDeletionManager: Sendable {

    public init() {}

    public func delete(fileURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            // Overwrite with random data before deletion
            let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            if fileSize > 0 {
                let randomData = generateRandomData(length: fileSize)
                try randomData.write(to: fileURL, options: .atomic)
            }
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw MnemoError.securityError("Secure deletion failed: \(error.localizedDescription)")
        }
    }

    public func wipeDatabase(at path: String) throws {
        // Wipe main database file and WAL/SHM sidecar files
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = URL(fileURLWithPath: path + suffix)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try delete(fileURL: fileURL)
            }
        }
    }

    private func generateRandomData(length: Int) -> Data {
        var data = Data(count: length)
        data.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            arc4random_buf(baseAddress, length)
        }
        return data
    }
}
