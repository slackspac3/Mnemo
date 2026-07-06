import Foundation
import MnemoCore

/// The normalised output of any capture pipeline.
/// All three input modalities (text, voice, image) produce a RawCapture.
/// Raw audio and image data never leave the device — only the text field
/// is ever passed to the extraction engine or cloud escalation path.
public struct RawCapture: Sendable {
    public let text: String
    public let source: InputSource
    public let userContext: String?          // Clarifying question answer (image flow)
    public let capturedAt: Date
    public let rawImageData: Data?           // Retained for display — never sent to cloud
    public let rawAudioTranscript: String?   // The raw transcript before user edits

    public init(
        text: String,
        source: InputSource,
        userContext: String? = nil,
        capturedAt: Date = Date(),
        rawImageData: Data? = nil,
        rawAudioTranscript: String? = nil
    ) {
        self.text = text
        self.source = source
        self.userContext = userContext
        self.capturedAt = capturedAt
        self.rawImageData = rawImageData
        self.rawAudioTranscript = rawAudioTranscript
    }
}
