import Testing
import Foundation
import SwiftData
@testable import MnemoMemory
import MnemoCore

@Suite("MnemoMemory")
struct MnemoMemoryTests {

    @Test("MemoryStore test container initialises")
    @MainActor
    func testContainerInit() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<MemoryRecord>())
        #expect(records.isEmpty)
    }

    @Test("MemoryRecord insert and fetch round trip")
    @MainActor
    func memoryRecordRoundTrip() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)

        let record = MemoryRecord(
            rawInput: "I wear a medium at Zara",
            summary: "Clothing size: medium at Zara",
            memoryType: .preference,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.95
        )

        try MemoryCRUD.insert(record, into: context)
        let fetched = try MemoryCRUD.fetchAll(in: context)
        #expect(fetched.count == 1)
        #expect(fetched.first?.summary == "Clothing size: medium at Zara")
    }

    @Test("MemoryRecord toSnapshot is consistent")
    @MainActor
    func snapshotConsistency() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)

        let record = MemoryRecord(
            rawInput: "Test",
            summary: "Test summary",
            memoryType: .fact,
            inputSource: .voice,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.75,
            confidence: 0.80
        )

        try MemoryCRUD.insert(record, into: context)
        let snapshot = record.toSnapshot()
        #expect(snapshot.memoryType == .fact)
        #expect(snapshot.processingTier == .onDevice)
    }

    @Test("MemoryThread insert and confirm")
    @MainActor
    func threadConfirmation() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)

        let thread = MemoryThread(
            name: "Flat search",
            proposalConfidence: 0.85
        )
        try ThreadCRUD.insert(thread, into: context)

        try ThreadCRUD.confirm(
            id: thread.id,
            name: "Dubai Flat Search",
            description: "Looking for a 2BR in JLT",
            startDate: Date(),
            endDate: nil,
            in: context
        )

        let fetched = try ThreadCRUD.fetch(id: thread.id, in: context)
        #expect(fetched?.isConfirmed == true)
        #expect(fetched?.name == "Dubai Flat Search")
    }

    @Test("UserModel default values are correct")
    @MainActor
    func userModelDefaults() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)

        let model = UserModel()
        context.insert(model)
        try context.save()

        #expect(model.onDeviceOnly == true)
        #expect(model.onboardingComplete == false)
        #expect(model.appLockEnabled == false)
        #expect(model.preferredSurface == "chat")

        let profile = model.decodedModalityThresholdProfile()
        #expect(profile.textThreshold == 0.90)
        #expect(profile.voiceThreshold == 0.75)
    }

    @Test("UserModel app lock setting persists locally")
    @MainActor
    func userModelAppLockPersists() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)

        let model = UserModel(appLockEnabled: true)
        context.insert(model)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserModel>()).first
        #expect(fetched?.appLockEnabled == true)
    }

    @Test("VectorBridge mock returns empty results")
    func vectorBridgeMock() async throws {
        let bridge = VectorBridge()
        let results = try await bridge.search(queryEmbedding: [0.1, 0.2, 0.3], limit: 10)
        #expect(results.isEmpty)
        let clusters = try await bridge.cluster(limit: 5)
        #expect(clusters.isEmpty)
    }
}
