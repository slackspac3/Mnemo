import Foundation
import SwiftData
import MnemoCore

/// Persisted user model. Stores the ModalityThresholdProfile, learning engine state,
/// PersonalisationIndex, and all feature opt-in flags.
/// There is exactly one UserModel per installation.
@Model
public final class UserModel {
    @Attribute(.unique) public var id: UUID
    public var modalityThresholdProfile: Data    // JSON: ModalityThresholdProfile
    public var captureFrequency: Data            // JSON: [String: Int] — MemoryType.rawValue counts
    public var recallFrequency: Data             // JSON: [String: Int] — memory UUID string counts
    public var preferredSurface: String          // 'chat' | 'browse'
    public var correctionPatterns: Data          // JSON: structured correction log
    public var persistencePreferences: Data      // JSON: [String: String] learned defaults
    public var personalisationIndex: Data        // JSON: PersonalisationIndex
    public var onboardingComplete: Bool
    public var cloudFallbackEnabled: Bool
    public var onDeviceOnly: Bool
    public var appLockEnabled: Bool = false
    public var memoryMomentsEnabled: Bool
    public var patternInsightsEnabled: Bool
    public var threadSuggestionsEnabled: Bool
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        onboardingComplete: Bool = false,
        cloudFallbackEnabled: Bool = false,
        onDeviceOnly: Bool = true,
        appLockEnabled: Bool = false,
        memoryMomentsEnabled: Bool = false,
        patternInsightsEnabled: Bool = true,
        threadSuggestionsEnabled: Bool = true
    ) {
        self.id = id
        self.modalityThresholdProfile = (try? JSONEncoder().encode(ModalityThresholdProfile())) ?? Data()
        self.captureFrequency = Data()
        self.recallFrequency = Data()
        self.preferredSurface = "chat"
        self.correctionPatterns = Data()
        self.persistencePreferences = Data()
        self.personalisationIndex = (try? JSONEncoder().encode(PersonalisationIndex())) ?? Data()
        self.onboardingComplete = onboardingComplete
        self.cloudFallbackEnabled = cloudFallbackEnabled
        self.onDeviceOnly = onDeviceOnly
        self.appLockEnabled = appLockEnabled
        self.memoryMomentsEnabled = memoryMomentsEnabled
        self.patternInsightsEnabled = patternInsightsEnabled
        self.threadSuggestionsEnabled = threadSuggestionsEnabled
        self.updatedAt = Date()
    }

    public convenience init(
        id: UUID,
        onboardingComplete: Bool,
        cloudFallbackEnabled: Bool,
        onDeviceOnly: Bool,
        memoryMomentsEnabled: Bool,
        patternInsightsEnabled: Bool,
        threadSuggestionsEnabled: Bool
    ) {
        self.init(
            id: id,
            onboardingComplete: onboardingComplete,
            cloudFallbackEnabled: cloudFallbackEnabled,
            onDeviceOnly: onDeviceOnly,
            appLockEnabled: false,
            memoryMomentsEnabled: memoryMomentsEnabled,
            patternInsightsEnabled: patternInsightsEnabled,
            threadSuggestionsEnabled: threadSuggestionsEnabled
        )
    }

    public func decodedModalityThresholdProfile() -> ModalityThresholdProfile {
        (try? JSONDecoder().decode(ModalityThresholdProfile.self, from: modalityThresholdProfile))
            ?? ModalityThresholdProfile()
    }

    public func decodedPersonalisationIndex() -> PersonalisationIndex {
        (try? JSONDecoder().decode(PersonalisationIndex.self, from: personalisationIndex))
            ?? PersonalisationIndex()
    }
}
