import Foundation
import SwiftData
import Testing
@testable import MnemoMemory
import MnemoCore

@Suite("Memory source card resolver")
@MainActor
struct MemorySourceCardResolverTests {

    @Test("Active source ID resolves to source-card-safe payload")
    func activeSourceIDResolvesToSourceCardSafePayload() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord(
            rawInput: "Raw private memory",
            summary: "Source card memory summary",
            source: .voice
        )
        try MemoryCRUD.insert(record, into: context)

        let resolvedPayload = try MemorySourceCardResolver().resolve(
            sourceIdentifier: record.id.uuidString,
            in: context
        )
        let payload = try #require(resolvedPayload)

        #expect(payload.id == record.id)
        #expect(payload.sourceIdentifier == record.id.uuidString)
        #expect(payload.summary == record.summary)
        #expect(payload.source == "Voice")
        #expect(payload.memoryType == record.memoryType)
        #expect(payload.createdAt == record.createdAt)
    }

    @Test("Malformed source ID fails closed")
    func malformedSourceIDFailsClosed() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)

        let payload = try MemorySourceCardResolver().resolve(
            sourceIdentifier: "not-a-uuid",
            in: context
        )

        #expect(payload == nil)
    }

    @Test("Missing source ID fails closed")
    func missingSourceIDFailsClosed() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)

        let payload = try MemorySourceCardResolver().resolve(
            sourceIdentifier: UUID().uuidString,
            in: context
        )

        #expect(payload == nil)
    }

    @Test("Archived source ID fails closed")
    func archivedSourceIDFailsClosed() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord(summary: "Archived source memory")
        record.isArchived = true
        try MemoryCRUD.insert(record, into: context)

        let payload = try MemorySourceCardResolver().resolve(
            sourceIdentifier: record.id.uuidString,
            in: context
        )

        #expect(payload == nil)
    }

    @Test("Permanently deleted source ID fails closed")
    func permanentlyDeletedSourceIDFailsClosed() async throws {
        try await VectorBridge.shared.wipe()
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord(summary: "Deleted source memory")
        try MemoryCRUD.insert(record, into: context)

        try await MemoryCRUD.deletePermanently(id: record.id, in: context)

        let payload = try MemorySourceCardResolver().resolve(
            sourceIdentifier: record.id.uuidString,
            in: context
        )

        #expect(payload == nil)
    }

    @Test("Payload uses MemoryRecord content, not Spotlight snippet content")
    func payloadUsesMemoryRecordContentNotSpotlightSnippetContent() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord(
            rawInput: "Private raw text from SwiftData",
            summary: "Trusted SwiftData summary",
            source: .text
        )
        try MemoryCRUD.insert(record, into: context)

        let candidate = MemorySearchSourceCandidate(
            sourceIdentifier: record.id.uuidString,
            title: "Misleading Spotlight title",
            snippet: "Misleading Spotlight snippet"
        )
        let resolvedPayload = try MemorySourceCardResolver().resolve(
            candidate: candidate,
            in: context
        )
        let payload = try #require(resolvedPayload)

        #expect(payload.summary == "Trusted SwiftData summary")
        #expect(payload.summary != candidate.title)
        #expect(payload.summary != candidate.snippet)
    }

    @Test("Source ID matches MemoryRecord ID string")
    func sourceIDMatchesMemoryRecordIDString() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord(summary: "Identity source memory")
        try MemoryCRUD.insert(record, into: context)

        let resolvedPayload = try MemorySourceCardResolver().resolve(
            sourceIdentifier: record.id.uuidString,
            in: context
        )
        let payload = try #require(resolvedPayload)

        #expect(payload.id == record.id)
        #expect(payload.sourceIdentifier == record.id.uuidString)
    }

    @Test("Deterministic recall remains independent of Spotlight source-card resolver")
    func deterministicRecallRemainsIndependentOfSpotlightSourceCardResolver() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = Self.makeRecord(summary: "Mum wears size 38 shoes")
        try MemoryCRUD.insert(record, into: context)

        let payload = try MemorySourceCardResolver().resolve(
            sourceIdentifier: record.id.uuidString,
            in: context
        )
        let result = RecallEngine().recall(
            query: "What size does mum wear?",
            memories: [record]
        )

        #expect(payload?.id == record.id)
        #expect(result.citedMemoryIds == [record.id])
        #expect(result.text.localizedCaseInsensitiveContains("38"))
    }

    private static func makeRecord(
        rawInput: String? = nil,
        summary: String,
        source: InputSource = .text
    ) -> MemoryRecord {
        MemoryRecord(
            rawInput: rawInput ?? summary,
            summary: summary,
            memoryType: .fact,
            inputSource: source,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.95
        )
    }
}
