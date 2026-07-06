import Foundation
import MnemoCore

/// Produces ThresholdUpdateEvents from user corrections.
/// These events are consumed by the ModalityThresholdLearningEngine in Phase 6
/// to update the user's per-modality confidence thresholds.
public struct ThresholdUpdateEventEmitter: Sendable {

    public init() {}

    /// Emit an event when the user edits a text extraction result.
    public func emitTextCorrection(
        original: ExtractionResult,
        correctedSummary: String
    ) -> ThresholdUpdateEvent {
        ThresholdUpdateEvent(
            source: .text,
            originalSummary: original.summary,
            correctedSummary: correctedSummary,
            semanticDelta: simpleDelta(original.summary, correctedSummary)
        )
    }

    /// Emit an event when the user edits a voice transcript.
    public func emitVoiceTranscriptCorrection(
        originalTranscript: String,
        correctedTranscript: String
    ) -> ThresholdUpdateEvent {
        ThresholdUpdateEvent(
            source: .voice,
            originalSummary: originalTranscript,
            correctedSummary: correctedTranscript,
            semanticDelta: simpleDelta(originalTranscript, correctedTranscript)
        )
    }

    /// Emit an event when the user edits an image extraction result.
    public func emitImageCorrection(
        original: ExtractionResult,
        correctedSummary: String
    ) -> ThresholdUpdateEvent {
        ThresholdUpdateEvent(
            source: .image,
            originalSummary: original.summary,
            correctedSummary: correctedSummary,
            semanticDelta: simpleDelta(original.summary, correctedSummary)
        )
    }

    /// Normalised character-level delta. 0.0 = identical, 1.0 = completely different.
    private func simpleDelta(_ a: String, _ b: String) -> Double {
        guard !a.isEmpty || !b.isEmpty else { return 0.0 }
        let longer = max(a.count, b.count)
        guard longer > 0 else { return 0.0 }
        let commonPrefix = zip(a, b).prefix(while: { $0.0 == $0.1 }).count
        return 1.0 - (Double(commonPrefix) / Double(longer))
    }
}
