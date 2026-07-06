import Foundation
import MnemoCore
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Vision)
import Vision
#endif

/// Handles image capture using Apple Vision VNRecognizeTextRequest for OCR.
/// Flow:
/// 1. User provides an image (camera or photo library)
/// 2. OCR extracts text
/// 3. ClarifyingQuestionPayload returned to UI
/// 4. User answers clarifying question: "What should I remember about this?"
/// 5. finalise() called with payload + user context to produce RawCapture
///
/// Raw image data never leaves the device and is never included in
/// cloud escalation payloads.
public struct ImageCaptureHandler: Sendable {

    public init() {}

    // MARK: - OCR

    #if canImport(UIKit) && canImport(Vision)
    public func capture(image: UIImage) async throws -> ClarifyingQuestionPayload {
        guard let cgImage = image.cgImage else {
            throw CaptureError.ocrFailed("Could not get CGImage from UIImage")
        }

        let extractedText = try await recogniseText(in: cgImage)
        let imageData = image.jpegData(compressionQuality: 0.7) ?? Data()

        return ClarifyingQuestionPayload(
            extractedText: extractedText,
            imageData: imageData
        )
    }
    #endif

    public func finalise(
        payload: ClarifyingQuestionPayload,
        userContext: String
    ) -> RawCapture {
        // Combine OCR text and user context.
        // User context is the most valuable signal — it comes first.
        let combinedText = userContext.isEmpty
            ? payload.extractedText
            : "\(userContext). \(payload.extractedText)"

        return RawCapture(
            text: combinedText,
            source: .image,
            userContext: userContext,
            rawImageData: payload.imageData
        )
    }

    // MARK: - Private

    #if canImport(UIKit) && canImport(Vision)
    private func recogniseText(in cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: CaptureError.ocrFailed(error.localizedDescription))
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: CaptureError.ocrFailed(error.localizedDescription))
            }
        }
    }
    #endif
}
