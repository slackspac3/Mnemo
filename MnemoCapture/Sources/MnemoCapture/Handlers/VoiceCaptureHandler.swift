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
    @Published public var isReceivingAudio: Bool = false
    @Published public var audioLevel: Double = 0.0
    @Published public var permissionGranted: Bool = false
    @Published public var recognitionErrorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizers: [SFSpeechRecognizer]

    public override init() {
        let currentLocale = Locale.current
        let englishFallback = Locale(identifier: "en_US")
        let preferredLocales: [Locale]
        if currentLocale.identifier.lowercased().hasPrefix("en") {
            preferredLocales = [englishFallback, currentLocale]
        } else {
            preferredLocales = [currentLocale, englishFallback]
        }
        self.speechRecognizers = preferredLocales.reduce(into: []) { recognizers, locale in
            guard
                !recognizers.contains(where: { $0.locale.identifier == locale.identifier }),
                let recognizer = SFSpeechRecognizer(locale: locale)
            else { return }
            recognizers.append(recognizer)
        }
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
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""
        isReceivingAudio = false
        audioLevel = 0.0
        recognitionErrorMessage = nil
        cleanupRecordingFile()

        guard let recognizer = availableSpeechRecognizer() else {
            throw CaptureError.transcriptionFailed("Speech recognition is not available right now")
        }

        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation

        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let tapFormat = inputNode.outputFormat(forBus: 0)
        guard tapFormat.sampleRate > 0, tapFormat.channelCount > 0 else {
            deactivateAudioSession()
            throw CaptureError.transcriptionFailed("Microphone input is not available")
        }

        let recordingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mnemo-voice-\(UUID().uuidString).caf")
        let audioFile = try AVAudioFile(
            forWriting: recordingURL,
            settings: tapFormat.settings
        )

        self.audioFile = audioFile
        self.recordingURL = recordingURL
        self.recognitionRequest = request

        var hasReportedAudio = false
        var lastLevelUpdate = Date.distantPast.timeIntervalSinceReferenceDate
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] buffer, _ in
            request.append(buffer)
            try? audioFile.write(from: buffer)

            let level = Self.normalizedAudioLevel(for: buffer)
            let now = Date.timeIntervalSinceReferenceDate
            if now - lastLevelUpdate >= 0.05 {
                lastLevelUpdate = now
                Task { @MainActor in
                    self?.audioLevel = level
                }
            }

            guard !hasReportedAudio, level > 0.04 else { return }
            hasReportedAudio = true
            Task { @MainActor in
                self?.isReceivingAudio = true
            }
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                Task { @MainActor in
                    self?.transcript = result.bestTranscription.formattedString
                }
            }

            if let error {
                Task { @MainActor in
                    self?.recognitionErrorMessage = error.localizedDescription
                }
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()

            self.audioEngine = audioEngine
            self.isRecording = true
        } catch {
            inputNode.removeTap(onBus: 0)
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest = nil
            cleanupRecordingFile()
            deactivateAudioSession()
            throw error
        }
    }

    public func stopRecording() -> RawCapture? {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.finish()

        audioEngine = nil
        recognitionRequest = nil
        isRecording = false
        audioLevel = 0.0
        deactivateAudioSession()

        let capturedTranscript = transcript
        guard !capturedTranscript.isEmpty else { return nil }

        return RawCapture(
            text: capturedTranscript,
            source: .voice,
            rawAudioTranscript: capturedTranscript
        )
    }

    public func stopRecordingAndTranscribe() async -> RawCapture? {
        if let capture = stopRecording() {
            cleanupRecordingFile()
            return capture
        }

        // Give the live recognition task a short chance to deliver its final text.
        for _ in 0..<10 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if let capture = currentCapture() {
                cleanupRecordingFile()
                return capture
            }
        }

        guard isReceivingAudio, let recordingURL else {
            cleanupRecordingFile()
            return nil
        }

        do {
            let fileTranscript = try await transcribeRecordingFile(at: recordingURL)
            let trimmed = fileTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                cleanupRecordingFile()
                return nil
            }

            transcript = trimmed
            cleanupRecordingFile()
            return RawCapture(
                text: trimmed,
                source: .voice,
                rawAudioTranscript: trimmed
            )
        } catch {
            recognitionErrorMessage = error.localizedDescription
            cleanupRecordingFile()
            return nil
        }
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

    private func availableSpeechRecognizer() -> SFSpeechRecognizer? {
        speechRecognizers.first(where: { $0.isAvailable })
    }

    private func currentCapture() -> RawCapture? {
        let capturedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !capturedTranscript.isEmpty else { return nil }
        return RawCapture(
            text: capturedTranscript,
            source: .voice,
            rawAudioTranscript: capturedTranscript
        )
    }

    private func transcribeRecordingFile(at url: URL) async throws -> String {
        guard let recognizer = availableSpeechRecognizer() else {
            throw CaptureError.transcriptionFailed("Speech recognition is not available right now")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let lock = NSLock()
            var didResume = false
            var bestTranscript = ""
            var timeoutTask: Task<Void, Never>?

            func finish(_ result: Result<String, Error>) {
                lock.lock()
                guard !didResume else {
                    lock.unlock()
                    return
                }
                didResume = true
                timeoutTask?.cancel()
                lock.unlock()

                continuation.resume(with: result)
            }

            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.taskHint = .dictation

            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                finish(.failure(CaptureError.transcriptionFailed("Speech recognition timed out")))
            }

            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    bestTranscript = result.bestTranscription.formattedString
                    if result.isFinal {
                        finish(.success(bestTranscript))
                    }
                }

                if let error {
                    if bestTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        finish(.failure(error))
                    } else {
                        finish(.success(bestTranscript))
                    }
                }
            }
        }
    }

    private func cleanupRecordingFile() {
        audioFile = nil
        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recordingURL = nil
    }

    private func deactivateAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    private nonisolated static func normalizedAudioLevel(for buffer: AVAudioPCMBuffer) -> Double {
        guard let channels = buffer.floatChannelData else { return 0.0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }

        var sum: Float = 0.0
        var sampleCount = 0
        for channelIndex in 0..<Int(buffer.format.channelCount) {
            let channel = channels[channelIndex]
            for frameIndex in 0..<frameLength {
                let sample = channel[frameIndex]
                sum += sample * sample
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return 0.0 }
        let rms = sqrt(sum / Float(sampleCount))
        return min(1.0, max(0.0, Double(rms) * 12.0))
    }
}
