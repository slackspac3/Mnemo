import SwiftUI
import SwiftData
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
    @State private var isExtracting = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedSummary: String?

    private let handler = TextCaptureHandler()
    private let engine = ExtractionEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.backgroundGrouped.ignoresSafeArea()

                VStack(spacing: DS.Spacing.lg) {
                    if let result = extractionResult {
                        ExtractionConfirmView(
                            result: result,
                            isSaving: isSaving,
                            onConfirm: { save(result: result) },
                            onEdit: {
                                guard !isSaving else { return }
                                extractionResult = nil
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
                        Text(error)
                            .font(DS.Typography.footnote)
                            .foregroundStyle(DS.Colours.destructive)
                            .padding(.horizontal, DS.Spacing.md)
                    }
                }
                .padding(DS.Spacing.md)
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

                await MainActor.run {
                    extractionResult = result
                    isExtracting = false
                }
            } catch {
                await MainActor.run {
                    HapticManager.error()
                    errorMessage = "Could not extract memory. Try again."
                    isExtracting = false
                }
            }
        }
    }

    private func save(result: ExtractionResult) {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        let rawInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        let record = MemoryRecord(
            rawInput: rawInput,
            summary: result.summary,
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
                    savedSummary = result.summary
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Could not save memory. Try again."
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
                        .padding(DS.Spacing.sm)
                        .background(DS.Colours.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
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
                            .font(DS.Typography.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                .padding(.vertical, DS.Spacing.xs)
                .background(canSave ? DS.ComponentTokens.PrimaryButton.background : DS.Colours.accentDisabled)
                .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }
            .disabled(!canSave || isExtracting)
            .buttonStyle(.mnemoPressable)
            .accessibilityLabel("Review memory")
            .accessibilityIdentifier(AccessibilityID.CaptureText.extract)

            Spacer()
        }
        .task {
            isFocused = true
        }
    }
}

struct ExtractionConfirmView: View {
    let result: ExtractionResult
    let isSaving: Bool
    let onConfirm: () -> Void
    let onEdit: () -> Void
    let onDiscard: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Review memory")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textSecondary)

                ZStack(alignment: .bottomTrailing) {
                    MnemoThreadMotif(style: .watermark, lineWidth: 1.8)
                        .frame(width: 120.0, height: 92.0)
                        .padding(.trailing, DS.Spacing.xs)

                    Text(result.summary)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DS.Spacing.md)
                        .padding(.trailing, DS.Spacing.sm)
                }
                .background(DS.Colours.memoryCardSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                        .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                .shadow(
                    color: DS.Shadows.subtle.color,
                    radius: DS.Shadows.subtle.radius,
                    x: DS.Shadows.subtle.x,
                    y: DS.Shadows.subtle.y
                )
                .transition(DS.Animation.cardAppearTransition(reduceMotion: reduceMotion))
                .accessibilityIdentifier(AccessibilityID.CaptureText.review)

                HStack(spacing: DS.Spacing.sm) {
                    Label(result.memoryType.rawValue.capitalized, systemImage: "tag")
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textSecondary)

                    Spacer()

                    Text(confidenceLabel)
                        .font(DS.Typography.caption1.weight(.semibold))
                        .foregroundStyle(result.confidence > 0.70 ? DS.Colours.success : DS.Colours.warning)
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(result.confidence > 0.70 ? DS.Colours.successSoft : DS.Colours.warningSoft)
                        .clipShape(Capsule())
                    }

                if !result.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.xs) {
                            ForEach(result.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(DS.Typography.caption1)
                                    .foregroundStyle(DS.Colours.accent)
                                    .padding(.horizontal, DS.Spacing.sm)
                                    .padding(.vertical, DS.Spacing.xs)
                                    .background(DS.Colours.surfaceSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            VStack(spacing: DS.Spacing.sm) {
                Button(action: onConfirm) {
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
                    .background(DS.ComponentTokens.PrimaryButton.background)
                    .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .disabled(isSaving)
                .buttonStyle(.mnemoPressable)
                .accessibilityIdentifier(AccessibilityID.CaptureText.save)

                Button(action: onEdit) {
                    Text("Edit")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: DS.ComponentTokens.SecondaryButton.height)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(DS.Colours.surfaceSecondary)
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                                .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
                        }
                        .foregroundStyle(DS.Colours.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .disabled(isSaving)
                .buttonStyle(.mnemoPressable)

                Button(action: onDiscard) {
                    Text("Discard")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                }
                .disabled(isSaving)
            }

            Spacer()
        }
    }

    private var confidenceLabel: String {
        if result.confidence < 0.50 {
            return "Review suggested"
        }

        return result.confidence > 0.70 ? "Looks ready" : "Check before saving"
    }
}
