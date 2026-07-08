import Foundation
import SwiftData
import MnemoCore

/// CRUD operations for MemoryRecord and PersonSubject.
public struct MemoryCRUD {

    // MARK: - Create

    public static func insert(_ record: MemoryRecord, into context: ModelContext) throws {
        context.insert(record)
        try context.save()
    }

    /// Insert a MemoryRecord and index it in the VectorBridge for semantic search.
    /// Call this instead of insert(_:into:) for all new captures in production.
    @MainActor
    public static func insertAndIndex(
        _ record: MemoryRecord,
        into context: ModelContext,
        searchIndexingFlags: MemorySearchIndexingFlags = .disabled,
        searchIndexer: (any MemorySearchIndexing)? = nil
    ) async throws {
        context.insert(record)
        try context.save()

        let helper = EmbeddingHelper()
        do {
            try await helper.index(id: record.id, summary: record.summary)
        } catch {
            do {
                try await helper.index(id: record.id, summary: record.summary)
            } catch {
                try? await rebuildIndex(in: context)
                throw error
            }
        }

        try await MemorySearchIndexingService(
            flags: searchIndexingFlags,
            indexer: searchIndexer
        ).indexIfNeeded(memory: record)

        #if DEBUG
        if !searchIndexingFlags.coreSpotlightIndexingEnabled {
            try await debugIndexForLocalAIChatIfNeeded(
                record,
                searchIndexer: searchIndexer
            )
        }
        #endif
    }

    /// Rebuild the VectorBridge index from the current non-archived SwiftData store.
    /// Use after restore or data repair so vector search matches the canonical store.
    @MainActor
    public static func rebuildIndex(in context: ModelContext) async throws {
        try await VectorBridge.shared.wipe()
        let snapshots = try fetchSnapshots(in: context)
        try await EmbeddingHelper().reindex(snapshots: snapshots)
    }

    #if DEBUG
    /// Backfill the internal DEBUG Local AI Chat Core Spotlight index.
    ///
    /// This deliberately bypasses the normal disabled default because it is
    /// only called from DEBUG-only app controls. Release builds do not compile
    /// this path and must not silently index private memories into Spotlight.
    @MainActor
    public static func backfillSearchIndex(
        in context: ModelContext,
        searchIndexer: (any MemorySearchIndexing)? = nil
    ) async throws {
        let searchIndexingService = MemorySearchIndexingService(
            flags: .debugCoreSpotlight,
            indexer: searchIndexer
        )
        let records = try fetchAll(in: context)
        for record in records where !record.isArchived {
            try await searchIndexingService.indexIfNeeded(memory: record)
        }
    }

    @MainActor
    static func debugIndexForLocalAIChatIfNeeded(
        _ record: MemoryRecord,
        searchIndexer: (any MemorySearchIndexing)? = nil,
        isEnabled: Bool = MemoryDebugLocalAIChatIndexing.isEnabled
    ) async throws {
        guard isEnabled, !record.isArchived else { return }
        try await MemorySearchIndexingService(
            flags: .debugCoreSpotlight,
            indexer: searchIndexer
        ).indexIfNeeded(memory: record)
    }
    #endif

    // MARK: - Read

    public static func fetchAll(
        in context: ModelContext,
        includeArchived: Bool = false
    ) throws -> [MemoryRecord] {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: includeArchived ? nil : #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public static func fetch(id: UUID, in context: ModelContext) throws -> MemoryRecord? {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    public static func fetchSnapshots(in context: ModelContext) throws -> [MemorySnapshot] {
        try fetchAll(in: context).map { $0.toSnapshot() }
    }

    // MARK: - Update

    public static func archive(id: UUID, in context: ModelContext) throws {
        guard let record = try fetch(id: id, in: context) else { return }
        record.isArchived = true
        record.updatedAt = Date()
        try context.save()
    }

    /// Archive a memory and remove its vector index row so hidden memories do
    /// not participate in vector-backed recall, corroboration, or threads.
    @MainActor
    public static func archiveAndUnindex(
        id: UUID,
        in context: ModelContext,
        searchIndexingFlags: MemorySearchIndexingFlags = .disabled,
        searchIndexer: (any MemorySearchIndexing)? = nil
    ) async throws {
        let searchIndexingService = MemorySearchIndexingService(
            flags: searchIndexingFlags,
            indexer: searchIndexer
        )

        guard let record = try fetch(id: id, in: context) else {
            try await VectorBridge.shared.delete(id: id)
            try await searchIndexingService.removeIfNeeded(memoryID: id)
            return
        }
        let summary = record.summary

        try await VectorBridge.shared.delete(id: id)
        try await searchIndexingService.removeIfNeeded(memoryID: id)

        do {
            record.isArchived = true
            record.updatedAt = Date()
            try context.save()
        } catch {
            record.isArchived = false
            try? await EmbeddingHelper().index(id: id, summary: summary)
            try? await searchIndexingService.indexIfNeeded(memory: record)
            throw error
        }
    }

    public static func markDone(id: UUID, in context: ModelContext) throws {
        guard let record = try fetch(id: id, in: context) else { return }
        record.isDone = true
        record.updatedAt = Date()
        try context.save()
    }

    public static func updatePersistenceScore(
        id: UUID,
        score: Double,
        state: PersistenceState,
        in context: ModelContext
    ) throws {
        guard let record = try fetch(id: id, in: context) else { return }
        record.persistenceScore = score
        record.persistenceState = state.rawValue
        record.updatedAt = Date()
        try context.save()
    }

    public static func appendProvenanceLink(
        _ link: ProvenanceLink,
        to id: UUID,
        in context: ModelContext
    ) throws {
        guard let record = try fetch(id: id, in: context) else { return }
        var chain = (try? JSONDecoder().decode([ProvenanceLink].self, from: record.provenanceChain)) ?? []
        chain.append(link)
        record.provenanceChain = (try? JSONEncoder().encode(chain)) ?? Data()
        record.updatedAt = Date()
        try context.save()
    }

    // MARK: - Delete

    /// Archive a memory without permanently deleting it.
    public static func softDelete(id: UUID, in context: ModelContext) throws {
        try archive(id: id, in: context)
    }

    /// Permanently delete one memory and remove its vector index row.
    /// This is the individual-memory privacy delete path.
    @MainActor
    public static func deletePermanently(
        id: UUID,
        in context: ModelContext,
        searchIndexingFlags: MemorySearchIndexingFlags = .disabled,
        searchIndexer: (any MemorySearchIndexing)? = nil
    ) async throws {
        let searchIndexingService = MemorySearchIndexingService(
            flags: searchIndexingFlags,
            indexer: searchIndexer
        )

        guard let record = try fetch(id: id, in: context) else {
            try await VectorBridge.shared.delete(id: id)
            try await searchIndexingService.removeIfNeeded(memoryID: id)
            return
        }
        let summary = record.summary

        try await VectorBridge.shared.delete(id: id)
        try await searchIndexingService.removeIfNeeded(memoryID: id)

        do {
            context.delete(record)
            try context.save()
        } catch {
            try? await EmbeddingHelper().index(id: id, summary: summary)
            try? await searchIndexingService.indexIfNeeded(memory: record)
            throw error
        }
    }

    /// Remove all Mnemo-owned items from the app search index.
    /// This follows the normal feature flag and is a no-op when indexing is off.
    @MainActor
    public static func removeAllSearchIndexItems(
        searchIndexingFlags: MemorySearchIndexingFlags = .disabled,
        searchIndexer: (any MemorySearchIndexing)? = nil
    ) async throws {
        try await MemorySearchIndexingService(
            flags: searchIndexingFlags,
            indexer: searchIndexer
        ).removeAllIfNeeded()
    }

    /// Always clear Mnemo-owned app search items for reset/privacy deletion.
    /// This is safe when nothing was indexed and keeps Delete All Data reliable
    /// even if internal indexing was previously enabled.
    @MainActor
    public static func resetSearchIndexItems(
        searchIndexer: (any MemorySearchIndexing)? = nil
    ) async throws {
        try await MemorySearchIndexingService(
            indexer: searchIndexer
        ).removeAllForReset()
    }
}
