import Foundation
import SwiftData
import MnemoCore
import MnemoSecurity

/// Configures and vends the SwiftData ModelContainer.
/// Applies NSFileProtectionComplete to database files on device after creation.
@MainActor
public final class MemoryStore {

    public static let shared = MemoryStore()

    public let container: ModelContainer

    private static var storeURL: URL {
        #if targetEnvironment(simulator)
        let storeDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("MnemoSimulatorStore", isDirectory: true)
        return storeDirectory.appendingPathComponent("default.store")
        #else
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("default.store")
        #endif
    }

    public init() {
        let schema = Schema([
            MemoryRecord.self,
            MemoryThread.self,
            UserModel.self,
            ConflictRecord.self,
            PersonSubject.self,
        ])
        do {
            try Self.prepareStoreDirectory()
            let config = ModelConfiguration(
                schema: schema,
                url: Self.storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            container = try ModelContainer(for: schema, configurations: [config])
            try Self.applyFileProtectionToStoreFiles()
        } catch {
            fatalError("MnemoMemory: Failed to create ModelContainer: \(error)")
        }
    }

    private static var storeFileURLs: [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
        ]
    }

    private static func prepareStoreDirectory() throws {
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private static func applyFileProtectionToStoreFiles() throws {
        #if os(iOS) && !targetEnvironment(simulator)
        let fileManager = FileManager.default
        for url in storeFileURLs where fileManager.fileExists(atPath: url.path) {
            try SecurityLayer.shared.applyFileProtection(to: url)
        }
        #endif
    }

    /// In-memory container for testing — does not persist to disk.
    public static func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([
            MemoryRecord.self,
            MemoryThread.self,
            UserModel.self,
            ConflictRecord.self,
            PersonSubject.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
