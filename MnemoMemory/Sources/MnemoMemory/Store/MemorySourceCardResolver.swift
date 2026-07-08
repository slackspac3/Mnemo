import Foundation
import SwiftData

public struct MemorySourceCardPayload: Equatable, Sendable {
    public let id: UUID
    public let sourceIdentifier: String
    public let summary: String
    public let source: String
    public let memoryType: String
    public let createdAt: Date
    public let updatedAt: Date

    public init(record: MemoryRecord) {
        self.id = record.id
        self.sourceIdentifier = record.id.uuidString
        self.summary = record.summary
        self.source = record.inputSource.capitalized
        self.memoryType = record.memoryType
        self.createdAt = record.createdAt
        self.updatedAt = record.updatedAt
    }
}

public struct MemorySearchSourceCandidate: Equatable, Sendable {
    public let sourceIdentifier: String
    public let title: String?
    public let snippet: String?

    public init(
        sourceIdentifier: String,
        title: String? = nil,
        snippet: String? = nil
    ) {
        self.sourceIdentifier = sourceIdentifier
        self.title = title
        self.snippet = snippet
    }
}

@MainActor
public struct MemorySourceCardResolver {
    private let indexingService: MemorySearchIndexingService

    public init(indexingService: MemorySearchIndexingService? = nil) {
        self.indexingService = indexingService ?? MemorySearchIndexingService()
    }

    public func resolve(
        sourceIdentifier: String,
        in context: ModelContext
    ) throws -> MemorySourceCardPayload? {
        guard let record = try indexingService.activeRecord(
            forSourceIdentifier: sourceIdentifier,
            in: context
        ) else {
            return nil
        }
        return MemorySourceCardPayload(record: record)
    }

    public func resolve(
        candidate: MemorySearchSourceCandidate,
        in context: ModelContext
    ) throws -> MemorySourceCardPayload? {
        try resolve(sourceIdentifier: candidate.sourceIdentifier, in: context)
    }
}
