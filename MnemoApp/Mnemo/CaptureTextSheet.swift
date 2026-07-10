import SwiftUI
import SwiftData
import UIKit
import MnemoUI
import MnemoCore
import MnemoCapture
import MnemoIntelligence
import MnemoMemory

/// Text capture sheet with extraction confirmation.
struct CaptureTextSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var inputText = ""
    @State private var extractionResult: ExtractionResult?
    @State private var reviewSummary = ""
    @State private var isExtracting = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedSummary: String?

    private let handler = TextCaptureHandler()
    private let normalizer = MemoryTextNormalizer()
    #if DEBUG
    private let engine = ExtractionEngine(aiCoreFlags: .debugLocalFoundationModelsExtraction)
    #else
    private let engine = ExtractionEngine()
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.backgroundGrouped.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        if let result = extractionResult {
                            MemoryCaptureReviewView(
                                result: result,
                                rawInput: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
                                summary: $reviewSummary,
                                isSaving: isSaving,
                                onSave: { summary in save(result: result, summary: summary) },
                                onBack: {
                                    guard !isSaving else { return }
                                    extractionResult = nil
                                    reviewSummary = ""
                                },
                                onDiscard: {
                                    guard !isSaving else { return }
                                    dismiss()
                                }
                            )
                        } else {
                            TextInputView(
                                text: $inputText,
                                isExtracting: isExtracting,
                                onExtract: { extract() }
                            )
                        }

                        if let error = errorMessage {
                            Label(error, systemImage: "exclamationmark.circle")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityAddTraits(.isStaticText)
                        }
                    }
                    .padding(DS.Spacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DS.Colours.textSecondary)
                    .accessibilityIdentifier(AccessibilityID.CaptureText.dismiss)
                }
            }
            .overlay {
                if let savedSummary {
                    MemorySavedOverlay(summary: savedSummary) {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityIdentifier("capture.text.sheet")
    }

    private func extract() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        HapticManager.impact(.light)
        isExtracting = true
        errorMessage = nil

        Task {
            do {
                let capture = try handler.capture(text: inputText)
                let result = try await engine.extract(
                    rawText: capture.text,
                    source: .text,
                    threshold: 0.90
                )
                let normalizedResult = await normalizer.normalize(
                    rawInput: capture.text,
                    extractionResult: result
                )

                await MainActor.run {
                    extractionResult = normalizedResult
                    reviewSummary = normalizedResult.summary
                    isExtracting = false
                    UIAccessibility.post(notification: .screenChanged, argument: "Review memory")
                }
            } catch {
                await MainActor.run {
                    HapticManager.error()
                    errorMessage = "Could not extract memory. Try again."
                    isExtracting = false
                    UIAccessibility.post(notification: .announcement, argument: errorMessage)
                }
            }
        }
    }

    private func save(result: ExtractionResult, summary: String) {
        guard !isSaving else { return }
        let approvedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !approvedSummary.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        let rawInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        let record = MemoryRecord(
            rawInput: rawInput,
            summary: approvedSummary,
            memoryType: result.memoryType,
            persistenceScore: result.persistenceScore,
            inputSource: .text,
            processingTier: result.processingTier,
            modalityThresholdUsed: result.modalityThresholdUsed,
            confidence: result.confidence,
            tags: result.tags
        )

        Task {
            do {
                try await MemoryCRUD.insertAndIndex(record, into: modelContext)
                await MainActor.run {
                    HapticManager.success()
                    savedSummary = approvedSummary
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Could not save memory. Try again."
                    UIAccessibility.post(notification: .announcement, argument: errorMessage)
                }
            }
        }
    }
}

struct TextInputView: View {
    @Binding var text: String
    let isExtracting: Bool
    let onExtract: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        let canSave = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        VStack(spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("What should Mnemo remember?")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                        .frame(minHeight: DS.Spacing.xxxl + DS.Spacing.xxxl)
                        .mnemoInputSurface(isFocused: isFocused)
                        .accessibilityIdentifier(AccessibilityID.CaptureText.input)
                        .accessibilityLabel("Memory text")
                        .accessibilityHint("Type what Mnemo should remember")

                    if text.isEmpty {
                        Text("Example: Mum wears size 38 shoes.")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colours.textTertiary)
                            .padding(.horizontal, DS.Spacing.md + DS.Spacing.xs)
                            .padding(.vertical, DS.Spacing.md)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
            }

            Button(action: onExtract) {
                HStack {
                    if isExtracting {
                        ProgressView()
                            .tint(DS.ComponentTokens.PrimaryButton.foreground)
                    } else {
                        Text("Review Memory")
                    }
                }
            }
            .disabled(!canSave || isExtracting)
            .buttonStyle(.mnemoPrimary)
            .accessibilityLabel("Review memory")
            .accessibilityIdentifier(AccessibilityID.CaptureText.extract)

        }
        .task {
            isFocused = true
        }
    }
}
