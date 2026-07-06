import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Intermediate payload produced by ImageCaptureHandler after OCR.
/// Held while the clarifying question UI is shown to the user.
/// The user's answer is attached as userContext before producing a RawCapture.
public struct ClarifyingQuestionPayload: Sendable {
    public let extractedText: String
    public let imageData: Data               // Compressed image for display in UI

    public init(extractedText: String, imageData: Data) {
        self.extractedText = extractedText
        self.imageData = imageData
    }
}
