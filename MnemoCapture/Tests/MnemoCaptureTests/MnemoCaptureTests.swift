import Testing
import Foundation
@testable import MnemoCapture
import MnemoCore

@Suite("MnemoCapture")
struct MnemoCaptureTests {

    @Test("TextCaptureHandler produces correct RawCapture")
    func textCaptureBasic() throws {
        let handler = TextCaptureHandler()
        let capture = try handler.capture(text: "  I wear a medium at Zara  ")
        #expect(capture.text == "I wear a medium at Zara")
        #expect(capture.source == .text)
        #expect(capture.rawImageData == nil)
    }

    @Test("TextCaptureHandler throws on empty input")
    func textCaptureEmpty() {
        let handler = TextCaptureHandler()
        #expect(throws: CaptureError.emptyInput) {
            try handler.capture(text: "   ")
        }
    }

    @Test("TextCaptureHandler throws on whitespace-only input")
    func textCaptureWhitespace() {
        let handler = TextCaptureHandler()
        #expect(throws: CaptureError.emptyInput) {
            try handler.capture(text: "\n\t  \n")
        }
    }

    @Test("ImageCaptureHandler finalise combines context and OCR text")
    func imageFinalise() {
        let handler = ImageCaptureHandler()
        let payload = ClarifyingQuestionPayload(
            extractedText: "Size: M",
            imageData: Data()
        )
        let capture = handler.finalise(payload: payload, userContext: "My Zara label")
        #expect(capture.source == .image)
        #expect(capture.text.contains("My Zara label"))
        #expect(capture.text.contains("Size: M"))
        #expect(capture.userContext == "My Zara label")
    }

    @Test("ImageCaptureHandler finalise uses OCR text when context is empty")
    func imageFinaliseEmptyContext() {
        let handler = ImageCaptureHandler()
        let payload = ClarifyingQuestionPayload(
            extractedText: "Extracted text only",
            imageData: Data()
        )
        let capture = handler.finalise(payload: payload, userContext: "")
        #expect(capture.text == "Extracted text only")
    }

    @Test("ThresholdUpdateEventEmitter produces correct source for text")
    func emitterTextSource() throws {
        let emitter = ThresholdUpdateEventEmitter()
        let original = ExtractionResult(
            summary: "Original summary",
            memoryType: .fact,
            persistenceScore: 0.5,
            confidence: 0.8,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            tags: []
        )
        let event = emitter.emitTextCorrection(
            original: original,
            correctedSummary: "Corrected summary"
        )
        #expect(event.source == .text)
        #expect(event.originalSummary == "Original summary")
        #expect(event.correctedSummary == "Corrected summary")
        #expect(event.semanticDelta >= 0.0)
        #expect(event.semanticDelta <= 1.0)
    }

    @Test("ThresholdUpdateEventEmitter delta is 0 for identical strings")
    func emitterZeroDelta() throws {
        let emitter = ThresholdUpdateEventEmitter()
        let original = ExtractionResult(
            summary: "Same text",
            memoryType: .fact,
            persistenceScore: 0.5,
            confidence: 0.8,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            tags: []
        )
        let event = emitter.emitTextCorrection(
            original: original,
            correctedSummary: "Same text"
        )
        #expect(event.semanticDelta == 0.0)
    }

    @Test("VoiceCaptureHandler correction event has voice source")
    @MainActor
    func voiceCorrectionEvent() {
        let handler = VoiceCaptureHandler()
        let event = handler.buildCorrectionEvent(
            original: "I wear medium",
            corrected: "I wear large"
        )
        #expect(event.source == .voice)
        #expect(event.semanticDelta > 0.0)
        #expect(event.semanticDelta <= 1.0)
    }
}
