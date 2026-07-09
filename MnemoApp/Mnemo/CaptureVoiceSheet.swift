import SwiftUI
import UIKit
import SwiftData
import MnemoUI
import MnemoCore
import MnemoCapture
import MnemoIntelligence
import MnemoMemory

/// Voice capture sheet with transcript confirm/edit before saving.
struct CaptureVoiceSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var voiceHandler = VoiceCaptureHandler()
    @State private var editedTranscript = ""
    @State private var showingConfirm = false
    @State private var permissionDenied = false
    @State private var isTranscribing = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedSummary: String?

    #if DEBUG
    private let engine = ExtractionEngine(aiCoreFlags: .debugLocalFoundationModelsExtraction)
    #else
    private let engine = ExtractionEngine()
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.backgroundGrouped.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xl) {
                    if permissionDenied {
                        PermissionDeniedView()
                    } else if showingConfirm {
                        VoiceConfirmView(
                            transcript: $editedTranscript,
                            isSaving: isSaving,
                            onSave: { saveTranscript() },
                            onRetry: {
                                showingConfirm = false
                                editedTranscript = ""
                                errorMessage = nil
                                isSaving = false
                            },
                            onDiscard: { dismiss() }
                        )
                    } else {
                        VoiceRecordingView(
                            isRecording: voiceHandler.isRecording,
                            isReceivingAudio: voiceHandler.isReceivingAudio,
                            isTranscribing: isTranscribing,
                            audioLevel: voiceHandler.audioLevel,
                            transcript: voiceHandler.transcript,
                            onToggle: { toggleRecording() },
                            onDone: {
                                editedTranscript = voiceHandler.transcript
                                showingConfirm = true
                            }
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DS.Typography.footnote)
                            .foregroundStyle(DS.Colours.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Spacing.md)
                    }
                }
                .padding(DS.Spacing.xl)
            }
            .navigationTitle("Voice Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if voiceHandler.isRecording {
                            _ = voiceHandler.stopRecording()
                        }
                        dismiss()
                    }
                    .foregroundStyle(DS.Colours.textSecondary)
                }
            }
            .task {
                let granted = await voiceHandler.requestPermission()
                if !granted {
                    permissionDenied = true
                }
            }
            .onChange(of: voiceHandler.transcript) { _, transcript in
                let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard isTranscribing, !trimmed.isEmpty else { return }
                editedTranscript = trimmed
                isTranscribing = false
                showingConfirm = true
            }
            .onChange(of: voiceHandler.recognitionErrorMessage) { _, message in
                guard let message, !message.isEmpty else { return }
                errorMessage = recognitionFailureMessage(message)
            }
            .overlay {
                if let savedSummary {
                    MemorySavedOverlay(summary: savedSummary) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleRecording() {
        errorMessage = nil

        if voiceHandler.isRecording {
            finishRecording()
        } else {
            isTranscribing = false
            do {
                try voiceHandler.startRecording()
                HapticManager.impact(.heavy)
            } catch {
                errorMessage = "Could not start recording: \(error.localizedDescription)"
            }
        }
    }

    private func finishRecording() {
        isTranscribing = true
        HapticManager.impact(.medium)

        Task {
            if let capture = await voiceHandler.stopRecordingAndTranscribe() {
                await MainActor.run {
                    editedTranscript = capture.text
                    errorMessage = nil
                    isTranscribing = false
                    showingConfirm = true
                }
            } else {
                await MainActor.run {
                    isTranscribing = false
                    if let message = voiceHandler.recognitionErrorMessage, !message.isEmpty {
                        showManualTranscriptFallback(message: recognitionFailureMessage(message))
                    } else {
                        let message = noSpeechMessage(receivedAudio: voiceHandler.isReceivingAudio)
                        if voiceHandler.isReceivingAudio {
                            showManualTranscriptFallback(message: message)
                        } else {
                            errorMessage = message
                        }
                    }
                }
            }
        }
    }

    private func noSpeechMessage(receivedAudio: Bool) -> String {
        if receivedAudio {
            return "Audio was received, but no words were recognized. Try again and speak clearly until you tap stop."
        }

        #if targetEnvironment(simulator)
        return "No microphone input reached the simulator. In Simulator, choose I/O > Audio Input > Mac Microphone, or test on a physical iPhone."
        #else
        return "No microphone input reached Mnemo. Check microphone access and try speaking closer to the phone."
        #endif
    }

    private func recognitionFailureMessage(_ message: String) -> String {
        if message.localizedCaseInsensitiveContains("initialize recognizer") {
            #if targetEnvironment(simulator)
            return "The simulator is receiving microphone input, but Apple speech recognition could not start. Type what you said below, or retry on a physical iPhone."
            #else
            return "Apple speech recognition could not start. Type what you said below, or restart the app and try again."
            #endif
        }

        return "Speech recognition could not finish: \(message)"
    }

    private func showManualTranscriptFallback(message: String) {
        editedTranscript = ""
        isSaving = false
        errorMessage = message
        showingConfirm = true
    }

    private func saveTranscript() {
        let transcript = editedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else {
            dismiss()
            return
        }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                let result = try await engine.extract(
                    rawText: transcript,
                    source: .voice,
                    threshold: 0.90
                )

                let record = MemoryRecord(
                    rawInput: transcript,
                    summary: result.summary,
                    memoryType: result.memoryType,
                    persistenceScore: result.persistenceScore,
                    inputSource: .voice,
                    processingTier: result.processingTier,
                    modalityThresholdUsed: result.modalityThresholdUsed,
                    confidence: result.confidence,
                    tags: result.tags
                )
                try await MemoryCRUD.insertAndIndex(record, into: modelContext)
                await MainActor.run {
                    HapticManager.success()
                    savedSummary = result.summary
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not save voice memory. Try again."
                    isSaving = false
                }
            }
        }
    }
}

struct VoiceRecordingView: View {
    let isRecording: Bool
    let isReceivingAudio: Bool
    let isTranscribing: Bool
    let audioLevel: Double
    let transcript: String
    let onToggle: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    @State private var displayedLevel = 0.0

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()

            ZStack {
                if isRecording {
                    Circle()
                        .stroke(DS.Colours.destructive.opacity(0.28), lineWidth: DS.Spacing.xs / 2)
                        .frame(
                            width: DS.Spacing.xxxl + DS.Spacing.xxxl,
                            height: DS.Spacing.xxxl + DS.Spacing.xxxl
                        )
                        .scaleEffect(pulse ? 1.08 : 0.88)
                        .opacity(pulse ? 0.24 : 0.72)
                        .animation(reduceMotion ? nil : DS.Animation.slow.repeatForever(autoreverses: true), value: pulse)
                }

                Circle()
                    .fill(isRecording ? DS.Colours.destructiveSoft : DS.Colours.surfaceSecondary)
                    .frame(
                        width: DS.Spacing.xxxl + DS.Spacing.xxl,
                        height: DS.Spacing.xxxl + DS.Spacing.xxl
                    )

                if isRecording {
                    Circle()
                        .stroke(DS.Colours.destructive, lineWidth: DS.Spacing.xs / DS.Spacing.xs)
                        .frame(
                            width: DS.Spacing.xxxl + DS.Spacing.xxxl,
                            height: DS.Spacing.xxxl + DS.Spacing.xxxl
                        )
                }

                Button {
                    guard !isTranscribing else { return }
                    onToggle()
                } label: {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(DS.Typography.largeTitle)
                        .foregroundStyle(isRecording ? DS.Colours.destructive : DS.Colours.accent)
                        .frame(width: 80.0, height: 80.0)
                        .scaleEffect(isRecording && !reduceMotion ? 1.0 + CGFloat(displayedLevel * 0.10) : 1.0)
                        .animation(reduceMotion ? nil : DS.Animation.quick, value: displayedLevel)
                }
                .disabled(isTranscribing)
                .accessibilityLabel(isRecording ? "Stop recording" : "Record voice memory")
                .accessibilityValue(statusText)
                .accessibilityHint(isRecording ? "Stop recording and finish the transcript" : "Start voice capture")
            }
            .onAppear {
                pulse = isRecording
                displayedLevel = audioLevel
            }
            .onChange(of: isRecording) { _, newValue in
                pulse = newValue
            }
            .onChange(of: audioLevel) { _, newValue in
                withAnimation(reduceMotion ? nil : DS.Animation.quick) {
                    displayedLevel = newValue
                }
            }

            if isRecording {
                RecordingWaveform(level: displayedLevel)
            }

            Text(statusText)
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colours.textSecondary)
                .multilineTextAlignment(.center)

            if isTranscribing {
                ProgressView()
                    .tint(DS.Colours.accent)
            }

            if !transcript.isEmpty {
                Text(transcript)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(DS.Spacing.md)
                    .background(DS.Colours.memoryCardSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                            .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))

                Button("Use this transcript") {
                    onDone()
                }
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colours.accent)
                .buttonStyle(.mnemoPressable)
            }

            Spacer()
        }
    }

    private var statusText: String {
        if isRecording {
            return isReceivingAudio ? "Recording... tap the stop button when finished" : "Recording... speak now"
        }
        if isTranscribing {
            return "Finishing transcript..."
        }
        return "Tap the microphone to start"
    }
}

struct RecordingWaveform: View {
    let level: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(DS.Colours.destructive)
                    .frame(
                        width: DS.Spacing.xs,
                        height: height(for: index)
                    )
                    .animation(reduceMotion ? nil : DS.Animation.quick, value: level)
            }
        }
        .frame(height: DS.Spacing.lg)
        .accessibilityHidden(true)
    }

    private func height(for index: Int) -> CGFloat {
        let low = DS.Spacing.sm
        let high = DS.Spacing.lg
        let multipliers = [0.50, 0.78, 1.0, 0.72, 0.46]
        let shapedLevel = max(0.06, min(1.0, level))
        return low + ((high - low) * CGFloat(shapedLevel * multipliers[index]))
    }
}

struct VoiceConfirmView: View {
    @Binding var transcript: String
    let isSaving: Bool
    let onSave: () -> Void
    let onRetry: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Text("Review transcript")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colours.textPrimary)

            TextEditor(text: $transcript)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(DS.Spacing.sm)
                .frame(minHeight: DS.Spacing.xxxl + DS.Spacing.xxl)
                .background(alignment: .topLeading) {
                    if transcript.isEmpty {
                        Text("Type what you said...")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colours.textTertiary)
                            .padding(DS.Spacing.md)
                    }
                }
                .background(DS.Colours.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))

            Button(action: onSave) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(DS.ComponentTokens.PrimaryButton.foreground)
                    } else {
                        Text("Save Memory")
                            .font(DS.Typography.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                .padding(.vertical, DS.Spacing.xs)
                .background(transcript.isEmpty ? DS.Colours.accentDisabled : DS.ComponentTokens.PrimaryButton.background)
                .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }
            .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            .buttonStyle(.mnemoPressable)

            Button(action: onRetry) {
                Text("Record again")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
            .buttonStyle(.mnemoPressable)

            Button(action: onDiscard) {
                Text("Discard")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
            .buttonStyle(.mnemoPressable)

            Spacer()
        }
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "mic.slash")
                .font(DS.Typography.largeTitle)
                .foregroundStyle(DS.Colours.textTertiary)
            Text("Microphone access required")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colours.textPrimary)
            Text("Go to Settings > Mnemo to enable microphone access.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(DS.Typography.headline)
            .foregroundStyle(DS.Colours.accent)
            .buttonStyle(.mnemoPressable)
        }
    }
}
