import SwiftUI
import SwiftData
import UIKit
import PhotosUI
import MnemoUI
import MnemoCore
import MnemoCapture
import MnemoIntelligence
import MnemoMemory

/// Image capture sheet with OCR and clarifying question flow.
struct CaptureImageSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var payload: ClarifyingQuestionPayload?
    @State private var clarifyingAnswer = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let handler = ImageCaptureHandler()
    private let engine = ExtractionEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.lg) {
                    if let payload {
                        ClarifyingQuestionView(
                            payload: payload,
                            answer: $clarifyingAnswer,
                            isSaving: isProcessing,
                            onSave: { saveCapture(payload: payload) },
                            onDiscard: { dismiss() }
                        )
                    } else {
                        ImageSelectionView(
                            selectedPhoto: $selectedPhoto,
                            isProcessing: isProcessing
                        )
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(DS.Typography.footnote)
                            .foregroundStyle(DS.Colours.destructive)
                    }
                }
                .padding(DS.Spacing.md)
            }
            .navigationTitle("Capture Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DS.Colours.textSecondary)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                processPhoto(item)
            }
        }
    }

    private func processPhoto(_ item: PhotosPickerItem) {
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw CaptureError.ocrFailed("Could not load image")
                }

                let result = try await handler.capture(image: image)
                await MainActor.run {
                    payload = result
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not read image. Try another photo."
                    isProcessing = false
                }
            }
        }
    }

    private func saveCapture(payload: ClarifyingQuestionPayload) {
        let userContext = clarifyingAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let extractedText = payload.extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userContext.isEmpty || !extractedText.isEmpty else {
            errorMessage = "Add a note about this image before saving."
            return
        }

        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let capture = handler.finalise(payload: payload, userContext: userContext)
                let result = try await engine.extract(
                    rawText: capture.text,
                    source: .image,
                    userContext: capture.userContext,
                    threshold: 0.90
                )
                let record = MemoryRecord(
                    rawInput: capture.text,
                    summary: result.summary,
                    memoryType: result.memoryType,
                    persistenceScore: result.persistenceScore,
                    inputSource: .image,
                    processingTier: result.processingTier,
                    modalityThresholdUsed: result.modalityThresholdUsed,
                    confidence: result.confidence,
                    tags: result.tags
                )

                try await MemoryCRUD.insertAndIndex(record, into: modelContext)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not save memory. Try again."
                    isProcessing = false
                }
            }
        }
    }
}

struct ImageSelectionView: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    let isProcessing: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(DS.Typography.largeTitle)
                .foregroundStyle(DS.Colours.textTertiary)

            Text("Choose a photo to capture")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colours.textPrimary)

            if isProcessing {
                ProgressView("Reading image...")
                    .font(DS.Typography.body)
                    .tint(DS.Colours.accent)
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text("Choose Photo")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.ComponentTokens.PrimaryButton.height)
                        .background(DS.Colours.accent)
                        .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
            }

            Spacer()
        }
    }
}

struct ClarifyingQuestionView: View {
    let payload: ClarifyingQuestionPayload
    @Binding var answer: String
    let isSaving: Bool
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            if let image = UIImage(data: payload.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: DS.Spacing.xxxl + DS.Spacing.xxxl + DS.Spacing.xxxl)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }

            if !payload.extractedText.isEmpty {
                Text("Extracted: \(payload.extractedText)")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("What should I remember about this?")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                TextField("e.g. my shoe size, a receipt, a label", text: $answer)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .padding(DS.Spacing.sm)
                    .background(DS.Colours.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }

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
                .frame(height: DS.ComponentTokens.PrimaryButton.height)
                .background(DS.Colours.accent)
                .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }
            .disabled(isSaving)

            Button(action: onDiscard) {
                Text("Discard")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
            }

            Spacer()
        }
    }
}
