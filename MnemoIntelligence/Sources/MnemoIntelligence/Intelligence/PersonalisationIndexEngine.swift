import Foundation
import MnemoCore
import MnemoMemory

/// Computes the PersonalisationIndex from UserModel state.
/// Surfaces as a user-visible transparency feature — Patent Candidate 4.
/// Shows what percentage of app behaviour is driven by the user's personal
/// model vs population-level defaults.
public final class PersonalisationIndexEngine: Sendable {

    public init() {}

    public func compute(from userModel: UserModel) -> PersonalisationIndex {
        let profile = userModel.decodedModalityThresholdProfile()

        let voiceActive = abs(profile.voiceThreshold - 0.75) > 0.05
        let imageActive = abs(profile.imageThreshold - 0.75) > 0.05

        let captureFreq = (try? JSONDecoder().decode(
            [String: Int].self,
            from: userModel.captureFrequency
        )) ?? [:]
        let totalCaptures = captureFreq.values.reduce(0, +)
        let persistenceLearned = min(1.0, Double(totalCaptures) / 50.0)

        let overall = computeOverall(
            voiceActive: voiceActive,
            imageActive: imageActive,
            persistenceLearned: persistenceLearned,
            threadCalibrated: false
        )

        return PersonalisationIndex(
            overall: overall,
            voiceProfileActive: voiceActive,
            imageProfileActive: imageActive,
            persistencePreferencesLearned: persistenceLearned,
            threadDetectionCalibrated: false
        )
    }

    public func breakdown(for index: PersonalisationIndex) -> [String] {
        var lines: [String] = []

        if index.voiceProfileActive {
            lines.append("Your voice accuracy profile is active.")
        } else {
            lines.append("Voice capture still uses default settings.")
        }

        if index.imageProfileActive {
            lines.append("Your image accuracy profile is active.")
        } else {
            lines.append("Image capture still uses default settings.")
        }

        let pct = Int(index.persistencePreferencesLearned * 100)
        lines.append("Your persistence preferences are \(pct)% learned.")

        return lines
    }

    private func computeOverall(
        voiceActive: Bool,
        imageActive: Bool,
        persistenceLearned: Double,
        threadCalibrated: Bool
    ) -> Double {
        var score = 0.0
        if voiceActive { score += 0.25 }
        if imageActive { score += 0.25 }
        score += persistenceLearned * 0.35
        if threadCalibrated { score += 0.15 }
        return min(1.0, score)
    }
}
