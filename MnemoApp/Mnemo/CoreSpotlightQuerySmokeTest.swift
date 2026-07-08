import Foundation
import SwiftData
import MnemoCore
import MnemoMemory

#if DEBUG
struct CoreSpotlightQuerySmokeTestResult: Equatable, Sendable {
    let indexed: Bool
    let queried: Bool
    let found: Bool
    let sourceValidated: Bool
    let archivedRejected: Bool
    let deletedRejected: Bool
    let cleared: Bool
    let durationMs: Double
    let errorMessage: String?
}

enum CoreSpotlightQuerySmokeTest {
    static let launchArgument = "--run-core-spotlight-query-smoke"

    static var shouldRunFromLaunchArguments: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    @MainActor
    static func run() async -> CoreSpotlightQuerySmokeTestResult {
        let startedAt = Date()
        let context = MemoryStore.shared.container.mainContext
        let indexer = CoreSpotlightMemoryIndexer()
        let service = MemorySearchIndexingService(
            flags: .debugCoreSpotlight,
            indexer: indexer,
            queryer: indexer
        )
        let token = "mnemospotlightsmoke\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
        let text = "Core Spotlight smoke memory waterfall guam private recall \(token)."
        let record = MemoryRecord(
            rawInput: text,
            summary: text,
            memoryType: .fact,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.95,
            tags: ["core-spotlight-smoke", token]
        )

        var indexed = false
        var queried = false
        var found = false
        var sourceValidated = false
        var archivedRejected = false
        var deletedRejected = false
        var cleared = false

        do {
            try await MemoryCRUD.insertAndIndex(
                record,
                into: context,
                searchIndexingFlags: .debugCoreSpotlight,
                searchIndexer: indexer
            )
            indexed = true

            found = try await waitForSourceID(
                record.id,
                matching: token,
                service: service
            )
            queried = true
            let activeRecord = try service.activeRecord(
                forSourceIdentifier: record.id.uuidString,
                in: context
            )
            sourceValidated = found && activeRecord?.id == record.id

            try await MemoryCRUD.archiveAndUnindex(
                id: record.id,
                in: context,
                searchIndexingFlags: .debugCoreSpotlight,
                searchIndexer: indexer
            )
            let archivedRecord = try service.activeRecord(
                forSourceIdentifier: record.id.uuidString,
                in: context
            )
            let archivedRecordRejected = archivedRecord == nil
            let archivedQueryAbsent = try await waitForSourceIDToDisappear(
                record.id,
                matching: token,
                service: service
            )
            archivedRejected = archivedRecordRejected || archivedQueryAbsent

            try await MemoryCRUD.deletePermanently(
                id: record.id,
                in: context,
                searchIndexingFlags: .debugCoreSpotlight,
                searchIndexer: indexer
            )
            let deletedRecord = try service.activeRecord(
                forSourceIdentifier: record.id.uuidString,
                in: context
            )
            let deletedRecordRejected = deletedRecord == nil
            let deletedQueryAbsent = try await waitForSourceIDToDisappear(
                record.id,
                matching: token,
                service: service
            )
            deletedRejected = deletedRecordRejected || deletedQueryAbsent

            try await MemoryCRUD.resetSearchIndexItems(searchIndexer: indexer)
            cleared = try await waitForSourceIDToDisappear(
                record.id,
                matching: token,
                service: service
            )

            let passed = indexed && queried && found && sourceValidated &&
                archivedRejected && deletedRejected && cleared
            return CoreSpotlightQuerySmokeTestResult(
                indexed: indexed,
                queried: queried,
                found: found,
                sourceValidated: sourceValidated,
                archivedRejected: archivedRejected,
                deletedRejected: deletedRejected,
                cleared: cleared,
                durationMs: Date().timeIntervalSince(startedAt) * 1_000,
                errorMessage: passed ? nil : "Core Spotlight query smoke did not satisfy all checks."
            )
        } catch {
            try? await MemoryCRUD.deletePermanently(
                id: record.id,
                in: context,
                searchIndexingFlags: .debugCoreSpotlight,
                searchIndexer: indexer
            )
            try? await MemoryCRUD.resetSearchIndexItems(searchIndexer: indexer)

            return CoreSpotlightQuerySmokeTestResult(
                indexed: indexed,
                queried: queried,
                found: found,
                sourceValidated: sourceValidated,
                archivedRejected: archivedRejected,
                deletedRejected: deletedRejected,
                cleared: cleared,
                durationMs: Date().timeIntervalSince(startedAt) * 1_000,
                errorMessage: error.localizedDescription
            )
        }
    }

    @MainActor
    private static func waitForSourceID(
        _ id: UUID,
        matching query: String,
        service: MemorySearchIndexingService
    ) async throws -> Bool {
        for _ in 0..<12 {
            let ids = try await service.sourceIdentifiersIfNeeded(matching: query, limit: 10)
            if ids.contains(id.uuidString) {
                return true
            }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        return false
    }

    @MainActor
    private static func waitForSourceIDToDisappear(
        _ id: UUID,
        matching query: String,
        service: MemorySearchIndexingService
    ) async throws -> Bool {
        for _ in 0..<12 {
            let ids = try await service.sourceIdentifiersIfNeeded(matching: query, limit: 10)
            if !ids.contains(id.uuidString) {
                return true
            }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        return false
    }
}
#endif
