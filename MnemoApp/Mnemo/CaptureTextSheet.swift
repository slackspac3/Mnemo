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
    @State private var errorMessage: String?

    private let handler = TextCaptureHandler()
    private let engine = ExtractionEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.lg) {
                    if let result = extractionResult {
                        ExtractionConfirmView(
                            result: result,
                            onConfirm: { save(result: result) },
                            onEdit: { extractionResult = nil },
                            onDiscard: { dismiss() }
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
                }
            }
        }
    }

    private func extract() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
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
                    errorMessage = "Could not extract memory. Try again."
                    isExtracting = false
                }
            }
        }
    }

    private func save(result: ExtractionResult) {
        let record = MemoryRecord(
            rawInput: inputText,
            summary: result.summary,
            memoryType: result.memoryType,
            persistenceScore: result.persistenceScore,
            inputSource: .text,
            processingTier: result.processingTier,
            modalityThresholdUsed: result.modalityThresholdUsed,
            confidence: result.confidence,
            tags: result.tags
        )

        modelContext.insert(record)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Could not save memory. Try again."
        }
    }
}

struct TextInputView: View {
    @Binding var text: String
    let isExtracting: Bool
    let onExtract: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("What do you want to remember?")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                TextEditor(text: $text)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: DS.Spacing.xxxl + DS.Spacing.xxxl)
                    .padding(DS.Spacing.sm)
                    .background(DS.Colours.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }

            Button(action: onExtract) {
                HStack {
                    if isExtracting {
                        ProgressView()
                            .tint(DS.ComponentTokens.PrimaryButton.foreground)
                    } else {
                        Text("Save to Memory")
                            .font(DS.Typography.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: DS.ComponentTokens.PrimaryButton.height)
                .background(text.isEmpty ? DS.Colours.textTertiary : DS.Colours.accent)
                .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }
            .disabled(text.isEmpty || isExtracting)

            Spacer()
        }
    }
}

struct ExtractionConfirmView: View {
    let result: ExtractionResult
    let onConfirm: () -> Void
    let onEdit: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Mnemo understood:")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textSecondary)

                Text(result.summary)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .padding(DS.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.Colours.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                    .shadow(
                        color: DS.Shadows.subtle.color,
                        radius: DS.Shadows.subtle.radius,
                        x: DS.Shadows.subtle.x,
                        y: DS.Shadows.subtle.y
                    )

                HStack(spacing: DS.Spacing.sm) {
                    Label(result.memoryType.rawValue.capitalized, systemImage: "tag")
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textSecondary)

                    Spacer()

                    Text("\(Int(result.confidence * 100))% confident")
                        .font(DS.Typography.caption1)
                        .foregroundStyle(result.confidence > 0.70 ? DS.Colours.success : DS.Colours.warning)
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
                    Text("Save Memory")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.ComponentTokens.PrimaryButton.height)
                        .background(DS.Colours.accent)
                        .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }

                Button(action: onEdit) {
                    Text("Edit")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.ComponentTokens.SecondaryButton.height)
                        .background(DS.Colours.surfaceSecondary)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }

                Button(action: onDiscard) {
                    Text("Discard")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                }
            }

            Spacer()
        }
    }
}
