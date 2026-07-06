import Foundation
import AVFoundation
import Combine
import MnemoCore
import Speech

/// Handles voice capture using iOS 18 native speech recognition.
/// Uses SFSpeechRecognizer (the production-grade API available in Swift Packages).
/// The transcript is shown to the user for confirm/edit before producing a RawCapture.
/// Every user edit to the transcript fires a ThresholdUpdateEvent.
///
/// IMPORTANT: Do NOT declare UIBackgroundModes audio in Info.plist.
/// Voice capture is foreground only. Background audio declaration
/// without a persistent audio use case causes App Store rejection.
@MainActor
public final class VoiceCaptureHandler: NSObject, ObservableObject {

    @Published public var transcript: String = ""
    @Published public var isRecording: Bool = false
    @Published public var permissionGranted: Bool = false

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?

    public override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        super.init()
    }

    // MARK: - Permission

    public func requestPermission() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        #if os(iOS)
        let audioStatus = await AVAudioApplication.requestRecordPermission()
        #else
        let audioStatus = true
        #endif

        permissionGranted = speechStatus == .authorized && audioStatus
        return permissionGranted
    }

    // MARK: - Recording

    public func startRecording() throws {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw CaptureError.transcriptionFailed("Speech recogniser unavailable")
        }

        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, _ in
            if let result {
                Task { @MainActor in
                    self?.transcript = result.bestTranscription.formattedString
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        self.audioEngine = audioEngine
        self.recognitionRequest = request
        self.isRecording = true
    }

    public func stopRecording() -> RawCapture? {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        let capturedTranscript = transcript
        guard !capturedTranscript.isEmpty else { return nil }

        return RawCapture(
            text: capturedTranscript,
            source: .voice,
            rawAudioTranscript: capturedTranscript
        )
    }

    // MARK: - User edit produces ThresholdUpdateEvent

    /// Called when the user edits the transcript in the confirm screen.
    /// Returns a ThresholdUpdateEvent that the learning engine uses to
    /// update the voice ModalityThresholdProfile.
    public func buildCorrectionEvent(
        original: String,
        corrected: String
    ) -> ThresholdUpdateEvent {
        let delta = semanticDelta(original: original, corrected: corrected)
        return ThresholdUpdateEvent(
            source: .voice,
            originalSummary: original,
            correctedSummary: corrected,
            semanticDelta: delta
        )
    }

    /// Simple character-level edit distance normalised to 0.0-1.0.
    /// Phase 12: replace with embedding-based semantic distance.
    private func semanticDelta(original: String, corrected: String) -> Double {
        guard !original.isEmpty else { return 1.0 }
        let distance = levenshteinDistance(original.lowercased(), corrected.lowercased())
        return min(1.0, Double(distance) / Double(max(original.count, 1)))
    }

    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        var dp = Array(repeating: Array(repeating: 0, count: bChars.count + 1), count: aChars.count + 1)
        for i in 0...aChars.count { dp[i][0] = i }
        for j in 0...bChars.count { dp[0][j] = j }
        for i in 1...aChars.count {
            for j in 1...bChars.count {
                dp[i][j] = aChars[i - 1] == bChars[j - 1]
                    ? dp[i - 1][j - 1]
                    : 1 + min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
            }
        }
        return dp[aChars.count][bChars.count]
    }
}
