import Foundation
import MnemoCore

/// Updates per-modality confidence thresholds based on user correction events.
/// Called after every user edit to a capture before confirmation.
/// This is the core of Patent Candidate 1 — per-modality adaptive thresholds
/// governed by individual correction history.
public final class ModalityThresholdLearningEngine: Sendable {

    /// Floor and ceiling prevent threshold drift to unusable extremes.
    public static let thresholdFloor: Double = 0.60
    public static let thresholdCeiling: Double = 0.95

    /// Minimum semantic delta to trigger a threshold adjustment.
    public static let adjustmentMinDelta: Double = 0.10

    public init() {}

    /// Process a ThresholdUpdateEvent and return an updated profile.
    /// - Parameters:
    ///   - event: The correction event from the capture pipeline
    ///   - profile: The current ModalityThresholdProfile (passed by value)
    /// - Returns: Updated profile with adjusted threshold for the corrected modality
    public func process(
        _ event: ThresholdUpdateEvent,
        profile: ModalityThresholdProfile
    ) -> ModalityThresholdProfile {
        guard event.semanticDelta >= Self.adjustmentMinDelta else {
            // Minor correction — threshold unchanged
            return profile
        }

        var updated = profile
        let current = profile.threshold(for: event.source)

        // Significant correction: lower threshold so future similar inputs
        // are more likely to escalate to cloud for better extraction quality.
        // Adjustment magnitude scales with correction severity.
        let adjustment = event.semanticDelta * 0.05
        let newThreshold = max(
            Self.thresholdFloor,
            min(Self.thresholdCeiling, current - adjustment)
        )

        switch event.source {
        case .text:
            updated.textThreshold = newThreshold
        case .voice:
            updated.voiceThreshold = newThreshold
        case .image:
            updated.imageThreshold = newThreshold
        }

        updated.lastUpdated = Date()
        return updated
    }

    /// Returns the current threshold for a modality from the profile.
    public func currentThreshold(
        for source: InputSource,
        profile: ModalityThresholdProfile
    ) -> Double {
        profile.threshold(for: source)
    }
}
