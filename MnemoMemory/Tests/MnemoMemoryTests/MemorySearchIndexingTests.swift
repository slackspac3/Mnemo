import Testing
import Foundation
import SwiftData
@testable import MnemoMemory
import MnemoCore

@Suite("Memory search indexing")
@MainActor
struct MemorySearchIndexingTests {

    @Test("Core Spotlight indexing flag defaults off")
    func coreSpotlightFlagDefaultsOff() {
        let flags = MemorySearchIndexingFlags()

        #expect(flags.coreSpotlightIndexingEnabled == false)
        #expect(MemorySearchIndexingFlags.disabled.coreSpotlightIndexingEnabled == false)
    }

    @Test("Active memory indexes only when flag is enabled")
    func activeMemoryIndexesOnlyWhenFlagEnabled() async throws {
        let record = Self.makeRecord("The waterfall I loved was in Guam")
        let fake = FakeMemorySearchIndexer()

        try await MemorySearchIndexingService(flags: .disabled, indexer: fake)
            .indexIfNeeded(memory: record)
        #expect(fake.indexedPayloads.isEmpty)

        try await MemorySearchIndexingService(flags: .debugCoreSpotlight, indexer: fake)
            .indexIfNeeded(memory: record)
        #expect(fake.indexedPayloads.map(\.memoryID) == [record.id])
    }

    @Test("Archived memory is not indexed")
    func archivedMemoryIsNotIndexed() async throws {
        let record = Self.makeRecord("Archived memory")
        record.isArchived = true
        let fake = FakeMemorySearchIndexer()

        try await MemorySearchIndexingService(flags: .debugCoreSpotlight, indexer: fake)
            .indexIfNeeded(memory: record)

        #expect(fake.indexedPayloads.isEmpty)
    }

    @Test("Source ID survives indexing payload creation")
    func sourceIDSurvivesPayloadCreation() throws {
        let record = Self.makeRecord(
            "Mum wears size 38 shoes",
            tags: ["shoe", "size"]
        )

        let payload = try #require(MemorySearchIndexPayload(memory: record))

        #expect(payload.memoryID == record.id)
        #expect(payload.uniqueIdentifier == record.id.uuidString)
        #expect(payload.domainIdentifier == MemorySearchIndexPayload.domainIdentifier)
        #expect(payload.title == record.summary)
        #expect(payload.contentDescription == record.summary)
        #expect(payload.sourceType == record.inputSource)
        #expect(payload.memoryType == record.memoryType)
        #expect(payload.keywords.contains(record.id.uuidString))
        #expect(payload.keywords.contains("shoe"))
    }

    @Test("Archive removes memory ID from search index")
    func archiveRemovesMemoryIDFromSearchIndex() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord("Mum wears size 38 shoes")
        let fake = FakeMemorySearchIndexer()

        try await MemoryCRUD.insertAndIndex(
            record,
            into: context,
            searchIndexingFlags: .debugCoreSpotlight,
            searchIndexer: fake
        )
        try await MemoryCRUD.archiveAndUnindex(
            id: record.id,
            in: context,
            searchIndexingFlags: .debugCoreSpotlight,
            searchIndexer: fake
        )

        #expect(fake.indexedPayloads.map(\.memoryID) == [record.id])
        #expect(fake.removedMemoryIDs == [record.id])
        #expect(try MemoryCRUD.fetch(id: record.id, in: context)?.isArchived == true)
    }

    @Test("Permanent delete removes memory ID from search index")
    func permanentDeleteRemovesMemoryIDFromSearchIndex() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord("Temporary test code is purple banana 123")
        let fake = FakeMemorySearchIndexer()

        try await MemoryCRUD.insertAndIndex(
            record,
            into: context,
            searchIndexingFlags: .debugCoreSpotlight,
            searchIndexer: fake
        )
        try await MemoryCRUD.deletePermanently(
            id: record.id,
            in: context,
            searchIndexingFlags: .debugCoreSpotlight,
            searchIndexer: fake
        )

        #expect(fake.indexedPayloads.map(\.memoryID) == [record.id])
        #expect(fake.removedMemoryIDs == [record.id])
        #expect(try MemoryCRUD.fetch(id: record.id, in: context) == nil)
    }

    @Test("Deleting missing memory removes orphaned search index ID")
    func deletingMissingMemoryRemovesOrphanedSearchIndexID() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let orphanID = UUID()
        let fake = FakeMemorySearchIndexer()

        try await MemoryCRUD.deletePermanently(
            id: orphanID,
            in: context,
            searchIndexingFlags: .debugCoreSpotlight,
            searchIndexer: fake
        )

        #expect(fake.indexedPayloads.isEmpty)
        #expect(fake.removedMemoryIDs == [orphanID])
    }

    @Test("Delete All Data search cleanup clears all even when indexing flag is off")
    func deleteAllDataSearchCleanupClearsAllEvenWhenIndexingFlagIsOff() async throws {
        let fake = FakeMemorySearchIndexer()

        try await MemoryCRUD.removeAllSearchIndexItems(
            searchIndexingFlags: .disabled,
            searchIndexer: fake
        )
        #expect(fake.removeAllCount == 0)

        try await MemoryCRUD.resetSearchIndexItems(searchIndexer: fake)
        #expect(fake.removeAllCount == 1)
    }

    @Test("Flag-gated remove all still only runs when enabled")
    func flagGatedRemoveAllStillOnlyRunsWhenEnabled() async throws {
        let fake = FakeMemorySearchIndexer()

        try await MemoryCRUD.removeAllSearchIndexItems(
            searchIndexingFlags: .debugCoreSpotlight,
            searchIndexer: fake
        )
        #expect(fake.removeAllCount == 1)
    }

    @Test("Source ID validation only returns active records")
    func sourceIDValidationOnlyReturnsActiveRecords() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let active = Self.makeRecord("Active source memory")
        let archived = Self.makeRecord("Archived source memory")
        archived.isArchived = true
        try MemoryCRUD.insert(active, into: context)
        try MemoryCRUD.insert(archived, into: context)

        let service = MemorySearchIndexingService(flags: .debugCoreSpotlight, indexer: FakeMemorySearchIndexer())

        #expect(try service.activeRecord(forSourceIdentifier: active.id.uuidString, in: context)?.id == active.id)
        #expect(try service.activeRecord(forSourceIdentifier: archived.id.uuidString, in: context) == nil)
        #expect(try service.activeRecord(forSourceIdentifier: UUID().uuidString, in: context) == nil)
        #expect(try service.activeRecord(forSourceIdentifier: "not-a-uuid", in: context) == nil)
    }

    @Test("Query source IDs validate only active records")
    func querySourceIDsValidateOnlyActiveRecords() async throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let active = Self.makeRecord("Core Spotlight active memory")
        let archived = Self.makeRecord("Core Spotlight archived memory")
        archived.isArchived = true
        let missingID = UUID()
        try MemoryCRUD.insert(active, into: context)
        try MemoryCRUD.insert(archived, into: context)

        let fake = FakeMemorySearchIndexer()
        fake.queryResultIDs = [
            active.id.uuidString,
            archived.id.uuidString,
            missingID.uuidString,
            "not-a-uuid",
        ]
        let service = MemorySearchIndexingService(
            flags: .debugCoreSpotlight,
            indexer: fake,
            queryer: fake
        )

        let sourceIDs = try await service.sourceIdentifiersIfNeeded(matching: "Core Spotlight")
        let activeRecords = try sourceIDs.compactMap {
            try service.activeRecord(forSourceIdentifier: $0, in: context)
        }

        #expect(sourceIDs == fake.queryResultIDs)
        #expect(activeRecords.map(\.id) == [active.id])
    }

    @Test("Query source IDs are hidden when feature flag is disabled")
    func querySourceIDsAreHiddenWhenFeatureFlagIsDisabled() async throws {
        let fake = FakeMemorySearchIndexer()
        fake.queryResultIDs = [UUID().uuidString]

        let sourceIDs = try await MemorySearchIndexingService(
            flags: .disabled,
            indexer: fake,
            queryer: fake
        ).sourceIdentifiersIfNeeded(matching: "anything")

        #expect(sourceIDs.isEmpty)
    }

    @Test("Deterministic recall remains independent of search indexing")
    func deterministicRecallRemainsIndependentOfSearchIndexing() async throws {
        let record = Self.makeRecord("Mum wears size 38 shoes")
        let fake = FakeMemorySearchIndexer()
        try await MemorySearchIndexingService(flags: .debugCoreSpotlight, indexer: fake)
            .indexIfNeeded(memory: record)

        let result = RecallEngine().recall(
            query: "What size does mum wear?",
            memories: [record]
        )

        #expect(fake.indexedPayloads.map(\.memoryID) == [record.id])
        #expect(result.citedMemoryIds == [record.id])
        #expect(result.text.localizedCaseInsensitiveContains("38"))
    }

    private static func makeRecord(
        _ summary: String,
        tags: [String] = []
    ) -> MemoryRecord {
        MemoryRecord(
            rawInput: summary,
            summary: summary,
            memoryType: .fact,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.95,
            tags: tags
        )
    }
}

@MainActor
private final class FakeMemorySearchIndexer: MemorySearchIndexing, MemorySearchQuerying {
    private(set) var indexedPayloads: [MemorySearchIndexPayload] = []
    private(set) var removedMemoryIDs: [UUID] = []
    private(set) var removeAllCount = 0
    var queryResultIDs: [String] = []

    func index(memory: MemoryRecord) async throws {
        if let payload = MemorySearchIndexPayload(memory: memory) {
            indexedPayloads.append(payload)
        }
    }

    func remove(memoryID: UUID) async throws {
        removedMemoryIDs.append(memoryID)
    }

    func removeAll() async throws {
        removeAllCount += 1
    }

    func sourceIdentifiers(matching query: String, limit: Int) async throws -> [String] {
        Array(queryResultIDs.prefix(limit))
    }
}
