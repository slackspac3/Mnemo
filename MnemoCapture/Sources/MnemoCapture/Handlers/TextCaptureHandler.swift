import Foundation
import MnemoCore

/// Handles typed or pasted text capture.
/// Validates, trims, and stamps a timestamp.
public struct TextCaptureHandler: Sendable {

    public init() {}

    /// Produce a RawCapture from a text string.
    /// Throws if the text is empty after trimming.
    public func capture(text: String) throws -> RawCapture {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CaptureError.emptyInput
        }
        return RawCapture(
            text: trimmed,
            source: .text
        )
    }
}

public enum CaptureError: Error, Sendable, Equatable {
    case emptyInput
    case transcriptionFailed(String)
    case ocrFailed(String)
    case permissionDenied
}
