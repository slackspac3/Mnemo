import Foundation
import SwiftData

#if canImport(CoreSpotlight)
import CoreSpotlight
#endif

public struct MemorySearchIndexingFlags: Equatable, Sendable {
    public var coreSpotlightIndexingEnabled: Bool

    public init(coreSpotlightIndexingEnabled: Bool = false) {
        self.coreSpotlightIndexingEnabled = coreSpotlightIndexingEnabled
    }

    public static let disabled = MemorySearchIndexingFlags()

    public static let debugCoreSpotlight = MemorySearchIndexingFlags(
        coreSpotlightIndexingEnabled: true
    )
}

#if DEBUG
/// Shared DEBUG-only key for the Local AI Chat fallback override.
///
/// MnemoMemory reads this raw UserDefaults key directly because the package
/// cannot depend on the app target's DebugAIChatSetting wrapper.
public enum MemoryDebugLocalAIChatIndexing {
    public static let deterministicOnlyUserDefaultsKey = "mnemo.debugDeterministicChatOnly"

    public static var isEnabled: Bool {
        !UserDefaults.standard.bool(forKey: deterministicOnlyUserDefaultsKey)
    }
}
#endif

public struct MemorySearchIndexPayload: Equatable, Sendable {
    public static let domainIdentifier = "com.thinkact.mnemo.memories"

    public let memoryID: UUID
    public let uniqueIdentifier: String
    public let domainIdentifier: String
    public let title: String
    public let contentDescription: String
    public let keywords: [String]
    public let sourceType: String
    public let memoryType: String
    public let createdAt: Date
    public let updatedAt: Date

    public init?(
        memory: MemoryRecord,
        domainIdentifier: String = Self.domainIdentifier
    ) {
        guard !memory.isArchived else { return nil }

        let summary = memory.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackTitle = memory.memoryTypeEnum?.rawValue.capitalized ?? "Memory"
        let title = summary.isEmpty ? fallbackTitle : summary
        let keywords = ([memory.memoryType, memory.inputSource, memory.id.uuidString] + memory.tags)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        self.memoryID = memory.id
        self.uniqueIdentifier = memory.id.uuidString
        self.domainIdentifier = domainIdentifier
        self.title = title
        self.contentDescription = summary
        self.keywords = Array(Set(keywords)).sorted()
        self.sourceType = memory.inputSource
        self.memoryType = memory.memoryType
        self.createdAt = memory.createdAt
        self.updatedAt = memory.updatedAt
    }
}

@MainActor
public protocol MemorySearchIndexing {
    func index(memory: MemoryRecord) async throws
    func remove(memoryID: UUID) async throws
    func removeAll() async throws
}

@MainActor
public protocol MemorySearchQuerying {
    func sourceIdentifiers(matching query: String, limit: Int) async throws -> [String]
}

@MainActor
public struct NoOpMemorySearchIndexer: MemorySearchIndexing, MemorySearchQuerying {
    public init() {}

    public func index(memory: MemoryRecord) async throws {}
    public func remove(memoryID: UUID) async throws {}
    public func removeAll() async throws {}
    public func sourceIdentifiers(matching query: String, limit: Int) async throws -> [String] { [] }
}

@MainActor
public struct MemorySearchIndexingService {
    public let flags: MemorySearchIndexingFlags
    private let indexer: any MemorySearchIndexing
    private let queryer: any MemorySearchQuerying

    public init(
        flags: MemorySearchIndexingFlags = .disabled,
        indexer: (any MemorySearchIndexing)? = nil,
        queryer: (any MemorySearchQuerying)? = nil
    ) {
        let coreSpotlightIndexer = CoreSpotlightMemoryIndexer()
        self.flags = flags
        self.indexer = indexer ?? coreSpotlightIndexer
        self.queryer = queryer ?? (indexer as? any MemorySearchQuerying) ?? coreSpotlightIndexer
    }

    public func indexIfNeeded(memory: MemoryRecord) async throws {
        guard flags.coreSpotlightIndexingEnabled else { return }
        guard !memory.isArchived else { return }
        try await indexer.index(memory: memory)
    }

    public func removeIfNeeded(memoryID: UUID) async throws {
        guard flags.coreSpotlightIndexingEnabled else { return }
        try await indexer.remove(memoryID: memoryID)
    }

    public func removeAllIfNeeded() async throws {
        guard flags.coreSpotlightIndexingEnabled else { return }
        try await indexer.removeAll()
    }

    public func removeAllForReset() async throws {
        try await indexer.removeAll()
    }

    public func sourceIdentifiersIfNeeded(
        matching query: String,
        limit: Int = 10
    ) async throws -> [String] {
        guard flags.coreSpotlightIndexingEnabled else { return [] }
        return try await queryer.sourceIdentifiers(matching: query, limit: limit)
    }

    public func activeRecord(
        forSourceIdentifier sourceIdentifier: String,
        in context: ModelContext
    ) throws -> MemoryRecord? {
        guard let id = UUID(uuidString: sourceIdentifier),
              let record = try MemoryCRUD.fetch(id: id, in: context),
              !record.isArchived
        else {
            return nil
        }
        return record
    }
}

#if canImport(CoreSpotlight)
@MainActor
public struct CoreSpotlightMemoryIndexer: MemorySearchIndexing, MemorySearchQuerying {
    public init() {}

    public func index(memory: MemoryRecord) async throws {
        guard let payload = MemorySearchIndexPayload(memory: memory) else { return }

        let attributes = CSSearchableItemAttributeSet(itemContentType: "public.text")
        attributes.title = payload.title
        attributes.displayName = payload.title
        attributes.contentDescription = payload.contentDescription
        attributes.keywords = payload.keywords

        let item = CSSearchableItem(
            uniqueIdentifier: payload.uniqueIdentifier,
            domainIdentifier: payload.domainIdentifier,
            attributeSet: attributes
        )
        item.expirationDate = .distantFuture

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().indexSearchableItems([item]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func remove(memoryID: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [memoryID.uuidString]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func removeAll() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().deleteSearchableItems(
                withDomainIdentifiers: [MemorySearchIndexPayload.domainIdentifier]
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func sourceIdentifiers(matching query: String, limit: Int) async throws -> [String] {
        guard let queryString = Self.queryString(for: query) else { return [] }

        let queryContext = CSSearchQueryContext()
        queryContext.fetchAttributes = ["title", "contentDescription", "keywords"]
        queryContext.filterQueries = [
            "domainIdentifier == \"\(MemorySearchIndexPayload.domainIdentifier)\""
        ]

        let searchQuery = CSSearchQuery(
            queryString: queryString,
            queryContext: queryContext
        )
        let lock = NSLock()
        var identifiers: [String] = []

        searchQuery.foundItemsHandler = { items in
            lock.lock()
            identifiers.append(
                contentsOf: items
                    .filter { $0.domainIdentifier == MemorySearchIndexPayload.domainIdentifier }
                    .map(\.uniqueIdentifier)
            )
            lock.unlock()
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
            searchQuery.completionHandler = { error in
                lock.lock()
                let result = Array(identifiers.prefix(max(limit, 0)))
                lock.unlock()

                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
            searchQuery.start()
        }
    }

    private static func queryString(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let escaped = trimmed
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return "(title == \"*\(escaped)*\"cd || contentDescription == \"*\(escaped)*\"cd || keywords == \"\(escaped)\"cd)"
    }
}
#else
@MainActor
public struct CoreSpotlightMemoryIndexer: MemorySearchIndexing, MemorySearchQuerying {
    public init() {}

    public func index(memory: MemoryRecord) async throws {}
    public func remove(memoryID: UUID) async throws {}
    public func removeAll() async throws {}
    public func sourceIdentifiers(matching query: String, limit: Int) async throws -> [String] { [] }
}
#endif
