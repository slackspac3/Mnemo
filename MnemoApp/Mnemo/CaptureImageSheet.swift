import SwiftUI
import UIKit
import PhotosUI
import MnemoUI
import MnemoCapture

/// Image capture sheet with OCR and clarifying question flow.
struct CaptureImageSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var payload: ClarifyingQuestionPayload?
    @State private var clarifyingAnswer = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let handler = ImageCaptureHandler()

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.lg) {
                    if let payload {
                        ClarifyingQuestionView(
                            payload: payload,
                            answer: $clarifyingAnswer,
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
        _ = handler.finalise(payload: payload, userContext: clarifyingAnswer)
        dismiss()
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
                Text("Save Memory")
                    .font(DS.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: DS.ComponentTokens.PrimaryButton.height)
                    .background(DS.Colours.accent)
                    .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
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
