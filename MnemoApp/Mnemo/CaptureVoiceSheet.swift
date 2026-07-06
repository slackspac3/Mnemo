import SwiftUI
import UIKit
import MnemoUI
import MnemoCapture

/// Voice capture sheet with transcript confirm/edit before saving.
struct CaptureVoiceSheet: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceHandler = VoiceCaptureHandler()
    @State private var editedTranscript = ""
    @State private var showingConfirm = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xl) {
                    if permissionDenied {
                        PermissionDeniedView()
                    } else if showingConfirm {
                        VoiceConfirmView(
                            transcript: $editedTranscript,
                            onSave: { saveTranscript() },
                            onRetry: {
                                showingConfirm = false
                                editedTranscript = ""
                            },
                            onDiscard: { dismiss() }
                        )
                    } else {
                        VoiceRecordingView(
                            isRecording: voiceHandler.isRecording,
                            transcript: voiceHandler.transcript,
                            onToggle: { toggleRecording() },
                            onDone: {
                                editedTranscript = voiceHandler.transcript
                                showingConfirm = true
                            }
                        )
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
        }
    }

    private func toggleRecording() {
        if voiceHandler.isRecording {
            _ = voiceHandler.stopRecording()
        } else {
            try? voiceHandler.startRecording()
        }
    }

    private func saveTranscript() {
        guard !editedTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            dismiss()
            return
        }

        dismiss()
    }
}

struct VoiceRecordingView: View {
    let isRecording: Bool
    let transcript: String
    let onToggle: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(isRecording ? DS.Colours.destructiveLight : DS.Colours.surfaceSecondary)
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

                Button(action: onToggle) {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(DS.Typography.largeTitle)
                        .foregroundStyle(isRecording ? DS.Colours.destructive : DS.Colours.accent)
                }
            }

            Text(isRecording ? "Tap to stop" : "Tap to record")
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colours.textSecondary)

            if !transcript.isEmpty {
                Text(transcript)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(DS.Spacing.md)
                    .background(DS.Colours.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))

                Button("Use this transcript") {
                    onDone()
                }
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colours.accent)
            }

            Spacer()
        }
    }
}

struct VoiceConfirmView: View {
    @Binding var transcript: String
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
                .frame(minHeight: DS.Spacing.xxxl + DS.Spacing.xxl)
                .padding(DS.Spacing.sm)
                .background(DS.Colours.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))

            Button(action: onSave) {
                Text("Save Memory")
                    .font(DS.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: DS.ComponentTokens.PrimaryButton.height)
                    .background(DS.Colours.accent)
                    .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }

            Button(action: onRetry) {
                Text("Record again")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
            }

            Button(action: onDiscard) {
                Text("Discard")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
            }

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
        }
    }
}
