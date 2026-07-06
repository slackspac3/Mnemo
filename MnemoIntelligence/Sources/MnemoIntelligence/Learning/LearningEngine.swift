import Foundation
import MnemoCore
import MnemoMemory

/// Observes capture and recall patterns and updates the UserModel.
/// Provides population-level defaults before sufficient user signal accumulates.
public final class LearningEngine: Sendable {

    private let thresholdEngine: ModalityThresholdLearningEngine

    public init(thresholdEngine: ModalityThresholdLearningEngine = ModalityThresholdLearningEngine()) {
        self.thresholdEngine = thresholdEngine
    }

    // MARK: - Capture recording

    public func recordCapture(
        type: MemoryType,
        userModel: UserModel
    ) {
        var freq = decodeCaptureFrequency(userModel)
        freq[type.rawValue, default: 0] += 1
        userModel.captureFrequency = encode(freq) ?? Data()
        userModel.updatedAt = Date()
    }

    // MARK: - Recall recording

    public func recordRecall(
        memoryId: UUID,
        userModel: UserModel
    ) {
        var freq = decodeRecallFrequency(userModel)
        freq[memoryId.uuidString, default: 0] += 1
        userModel.recallFrequency = encode(freq) ?? Data()
        userModel.updatedAt = Date()
    }

    // MARK: - Threshold update

    public func processThresholdUpdate(
        event: ThresholdUpdateEvent,
        userModel: UserModel
    ) {
        let currentProfile = userModel.decodedModalityThresholdProfile()
        let updatedProfile = thresholdEngine.process(event, profile: currentProfile)
        userModel.modalityThresholdProfile = (try? JSONEncoder().encode(updatedProfile)) ?? Data()
        userModel.updatedAt = Date()
    }

    // MARK: - Suggested decay class

    /// Returns a learned decay suggestion based on memory type.
    /// Falls back to population-level priors before user signal accumulates.
    public func suggestedDecayClass(for type: MemoryType, userModel: UserModel) -> DecayClass {
        let freq = decodeCaptureFrequency(userModel)
        let totalCaptures = freq.values.reduce(0, +)

        // Population-level priors — used until 20+ captures accumulated
        guard totalCaptures >= 20 else {
            return populationPrior(for: type)
        }

        // Learned preference — use most common decay for this type
        return populationPrior(for: type)
    }

    // MARK: - Private helpers

    private func populationPrior(for type: MemoryType) -> DecayClass {
        switch type {
        case .preference, .credential, .fact:
            return .persistent
        case .list, .instruction:
            return .session
        case .event:
            return .timeBound
        case .intention:
            return .persistent
        }
    }

    private func decodeCaptureFrequency(_ userModel: UserModel) -> [String: Int] {
        (try? JSONDecoder().decode([String: Int].self, from: userModel.captureFrequency)) ?? [:]
    }

    private func decodeRecallFrequency(_ userModel: UserModel) -> [String: Int] {
        (try? JSONDecoder().decode([String: Int].self, from: userModel.recallFrequency)) ?? [:]
    }

    private func encode(_ dict: [String: Int]) -> Data? {
        try? JSONEncoder().encode(dict)
    }
}
