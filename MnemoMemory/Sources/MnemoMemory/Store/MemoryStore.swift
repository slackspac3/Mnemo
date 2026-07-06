import Foundation
import SwiftData
import MnemoCore
import MnemoSecurity

/// Configures and vends the SwiftData ModelContainer.
/// Applies NSFileProtectionComplete to the database files after creation.
@MainActor
public final class MemoryStore {

    public static let shared = MemoryStore()

    public let container: ModelContainer

    public init() {
        let schema = Schema([
            MemoryRecord.self,
            MemoryThread.self,
            UserModel.self,
            ConflictRecord.self,
            PersonSubject.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("MnemoMemory: Failed to create ModelContainer: \(error)")
        }
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
