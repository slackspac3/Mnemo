import Testing
import Foundation
@testable import MnemoIntelligence
import MnemoCore
import MnemoMemory
import SwiftData

@Suite("MnemoIntelligence — Learning")
struct LearningTests {

    @Test("ModalityThresholdLearningEngine lowers threshold on significant correction")
    func thresholdLowersOnCorrection() {
        let engine = ModalityThresholdLearningEngine()
        let profile = ModalityThresholdProfile()
        let event = ThresholdUpdateEvent(
            source: .voice,
            originalSummary: "I wear medium",
            correctedSummary: "I wear extra large in this brand",
            semanticDelta: 0.8
        )
        let updated = engine.process(event, profile: profile)
        #expect(updated.voiceThreshold < profile.voiceThreshold)
        #expect(updated.voiceThreshold >= ModalityThresholdLearningEngine.thresholdFloor)
    }

    @Test("ModalityThresholdLearningEngine ignores minor corrections")
    func thresholdUnchangedOnMinorCorrection() {
        let engine = ModalityThresholdLearningEngine()
        let profile = ModalityThresholdProfile()
        let event = ThresholdUpdateEvent(
            source: .text,
            originalSummary: "Wear medium",
            correctedSummary: "Wear medium.",
            semanticDelta: 0.02
        )
        let updated = engine.process(event, profile: profile)
        #expect(updated.textThreshold == profile.textThreshold)
    }

    @Test("ModalityThresholdLearningEngine only updates the correct modality")
    func thresholdUpdatesCorrectModality() {
        let engine = ModalityThresholdLearningEngine()
        let profile = ModalityThresholdProfile()
        let event = ThresholdUpdateEvent(
            source: .image,
            originalSummary: "Size M",
            correctedSummary: "Size XL winter collection",
            semanticDelta: 0.75
        )
        let updated = engine.process(event, profile: profile)
        #expect(updated.imageThreshold < profile.imageThreshold)
        #expect(updated.textThreshold == profile.textThreshold)
        #expect(updated.voiceThreshold == profile.voiceThreshold)
    }

    @Test("PersistenceEngine computes score in valid range")
    @MainActor
    func persistenceScoreRange() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let record = MemoryRecord(
            rawInput: "Test",
            summary: "Test memory",
            memoryType: .fact,
            inputSource: .text,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.85
        )
        context.insert(record)
        try context.save()

        let engine = PersistenceEngine()
        let score = engine.computeScore(for: record)
        #expect(score >= 0.0)
        #expect(score <= 1.0)
    }

    @Test("PersistenceEngine state from score")
    func persistenceStateFromScore() {
        let engine = PersistenceEngine()
        #expect(engine.persistenceState(from: 0.8) == .active)
        #expect(engine.persistenceState(from: 0.35) == .dormant)
        #expect(engine.persistenceState(from: 0.1) == .review)
    }

    @Test("PersonalisationIndexEngine overall starts at zero for fresh user")
    @MainActor
    func personalisationStartsAtZero() throws {
        let container = try MemoryStore.makeTestContainer()
        let context = ModelContext(container)
        let userModel = UserModel()
        context.insert(userModel)
        try context.save()

        let engine = PersonalisationIndexEngine()
        let index = engine.compute(from: userModel)
        #expect(index.overall < 0.1)
        #expect(index.voiceProfileActive == false)
        #expect(index.imageProfileActive == false)
    }

    @Test("PatternInsightsEngine returns empty for fresh user")
    @MainActor
    func patternInsightsEmptyForFreshUser() throws {
        let container = try MemoryStore.makeTestContainer()
        _ = ModelContext(container)
        let engine = PatternInsightsEngine()
        let userModel = UserModel()
        let insights = engine.generateInsights(userModel: userModel, memories: [])
        #expect(insights.isEmpty)
    }

    @Test("ThreadDetectionEngine returns empty proposals from mock VectorBridge")
    func threadDetectionEmptyFromMock() async throws {
        let engine = ThreadDetectionEngine()
        let proposals = try await engine.runDetection(allMemories: [])
        #expect(proposals.isEmpty)
    }
}
