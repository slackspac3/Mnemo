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

    let source: ImageCaptureSource

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cameraImage: UIImage?
    @State private var isShowingCamera = false
    @State private var hasAutoOpenedCamera = false
    @State private var payload: ClarifyingQuestionPayload?
    @State private var clarifyingAnswer = ""
    @State private var extractionResult: ExtractionResult?
    @State private var reviewRawInput = ""
    @State private var reviewSummary = ""
    @State private var isProcessing = false
    @State private var isCommitting = false
    @State private var errorMessage: String?
    @State private var savedSummary: String?

    private let handler = ImageCaptureHandler()
    #if DEBUG
    private let normalizer = MemoryTextNormalizer(aiCoreFlags: .debugLocalFoundationModelsExtraction)
    private let engine = ExtractionEngine(aiCoreFlags: .debugLocalFoundationModelsExtraction)
    #else
    private let normalizer = MemoryTextNormalizer()
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
                                rawInput: reviewRawInput,
                                summary: $reviewSummary,
                                isSaving: isProcessing,
                                onSave: { summary in save(result: result, summary: summary) },
                                onBack: {
                                    guard !isCommitting else { return }
                                    extractionResult = nil
                                    reviewRawInput = ""
                                    reviewSummary = ""
                                },
                                onDiscard: {
                                    guard !isCommitting else { return }
                                    dismiss()
                                }
                            )
                        } else if let payload {
                            ClarifyingQuestionView(
                                payload: payload,
                                answer: $clarifyingAnswer,
                                isSaving: isProcessing,
                                onSave: { prepareReview(payload: payload) },
                                onRetry: { resetSelection() },
                                onDiscard: {
                                    guard !isProcessing else { return }
                                    dismiss()
                                }
                            )
                        } else {
                            ImageSelectionView(
                                selectedPhoto: $selectedPhoto,
                                source: source,
                                isProcessing: isProcessing
                            ) {
                                openCamera()
                            }
                        }

                        if let error = errorMessage {
                            Label(error, systemImage: "exclamationmark.circle")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(DS.Spacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(source == .camera ? "Take Photo" : "Choose Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        guard !isCommitting else { return }
                        dismiss()
                    }
                    .foregroundStyle(DS.Colours.textSecondary)
                    .disabled(isCommitting)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                processPhoto(item)
            }
            .onChange(of: cameraImage) { _, image in
                guard let image else { return }
                processImage(image)
            }
            .onAppear {
                if source == .camera, !hasAutoOpenedCamera {
                    hasAutoOpenedCamera = true
                    openCamera()
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraImagePicker(image: $cameraImage)
                    .ignoresSafeArea()
            }
            .overlay {
                if let savedSummary {
                    MemorySavedOverlay(summary: savedSummary) {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(isCommitting)
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

                try await processImageData(image)
            } catch {
                await MainActor.run {
                    errorMessage = "Could not read image. Try another photo."
                    isProcessing = false
                    UIAccessibility.post(notification: .announcement, argument: errorMessage)
                }
            }
        }
    }

    private func processImage(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                try await processImageData(image)
            } catch {
                await MainActor.run {
                    errorMessage = "Could not read image. Try another photo."
                    isProcessing = false
                    UIAccessibility.post(notification: .announcement, argument: errorMessage)
                }
            }
        }
    }

    private func processImageData(_ image: UIImage) async throws {
        let result = try await handler.capture(image: image)
        await MainActor.run {
            payload = result
            isProcessing = false
            UIAccessibility.post(notification: .screenChanged, argument: "Review image memory")
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = "Camera is not available on this device. Choose a photo instead."
            return
        }

        errorMessage = nil
        isShowingCamera = true
    }

    private func resetSelection() {
        selectedPhoto = nil
        cameraImage = nil
        payload = nil
        clarifyingAnswer = ""
        extractionResult = nil
        reviewRawInput = ""
        reviewSummary = ""
        errorMessage = nil
        isProcessing = false
        UIAccessibility.post(notification: .screenChanged, argument: "Choose another image")
    }

    private func prepareReview(payload: ClarifyingQuestionPayload) {
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
                let normalizedResult = await normalizer.normalize(
                    rawInput: capture.text,
                    extractionResult: result
                )

                await MainActor.run {
                    reviewRawInput = capture.text
                    extractionResult = normalizedResult
                    reviewSummary = normalizedResult.summary
                    isProcessing = false
                    UIAccessibility.post(notification: .screenChanged, argument: "Review memory")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not prepare memory. Try again."
                    isProcessing = false
                    UIAccessibility.post(notification: .announcement, argument: errorMessage)
                }
            }
        }
    }

    private func save(result: ExtractionResult, summary: String) {
        guard !isProcessing else { return }
        let rawInput = reviewRawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let approvedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawInput.isEmpty, !approvedSummary.isEmpty else { return }

        isProcessing = true
        isCommitting = true
        errorMessage = nil

        Task {
            do {
                let record = MemoryRecord(
                    rawInput: rawInput,
                    summary: approvedSummary,
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
                    HapticManager.success()
                    savedSummary = approvedSummary
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not save memory. Try again."
                    isProcessing = false
                    isCommitting = false
                    UIAccessibility.post(notification: .announcement, argument: errorMessage)
                }
            }
        }
    }
}

struct ImageSelectionView: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    let source: ImageCaptureSource
    let isProcessing: Bool
    let onCamera: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Image(systemName: source == .camera ? "camera.viewfinder" : "photo.on.rectangle.angled")
                .font(DS.Typography.largeTitle)
                .foregroundStyle(DS.Colours.textTertiary)

            VStack(spacing: DS.Spacing.xs) {
                Text("Capture an image memory")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                Text("Use the camera now, or choose a photo you already have.")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)

            if source == .camera, !UIImagePickerController.isSourceTypeAvailable(.camera) {
                Label("Camera is not available here", systemImage: "camera.fill")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.warning)
            }

            if isProcessing {
                ProgressView("Reading text in image...")
                    .font(DS.Typography.body)
                    .tint(DS.Colours.accent)
            } else {
                Button(action: onCamera) {
                    Label("Take Photo", systemImage: "camera.fill")
                }
                .buttonStyle(.mnemoPrimary)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                }
                .buttonStyle(.mnemoSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xl)
    }
}

struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let image: Binding<UIImage?>
        private let dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            self.image = image
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            image.wrappedValue = info[.originalImage] as? UIImage
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

struct ClarifyingQuestionView: View {
    let payload: ClarifyingQuestionPayload
    @Binding var answer: String
    let isSaving: Bool
    let onSave: () -> Void
    let onRetry: () -> Void
    let onDiscard: () -> Void
    @FocusState private var isAnswerFocused: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            if let image = UIImage(data: payload.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: DS.Spacing.xxxl + DS.Spacing.xxxl + DS.Spacing.xxxl)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                    .accessibilityLabel("Selected memory image")
                    .accessibilityAddTraits(.isImage)
            }

            if !payload.extractedText.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Label("Text found in image", systemImage: "text.viewfinder")
                        .font(DS.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Colours.textPrimary)

                    Text(payload.extractedText)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Spacing.md)
                .background(DS.Colours.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("What should I remember about this?")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                TextEditor(text: $answer)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($isAnswerFocused)
                    .frame(minHeight: 96.0)
                    .background(alignment: .topLeading) {
                        if answer.isEmpty {
                            Text("Add context, such as why this matters or what to recall")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colours.textTertiary)
                                .padding(DS.Spacing.md)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .mnemoInputSurface(isFocused: isAnswerFocused)
                    .accessibilityLabel("Memory context")
            }

            Button(action: onSave) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(DS.ComponentTokens.PrimaryButton.foreground)
                    } else {
                        Text("Review Memory")
                    }
                }
            }
            .disabled(isSaving)
            .buttonStyle(.mnemoPrimary)
            .accessibilityLabel(isSaving ? "Preparing memory" : "Review memory")
            .accessibilityValue(isSaving ? "In progress" : "")

            Button(action: onRetry) {
                Label("Choose another image", systemImage: "arrow.counterclockwise")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.accent)
                    .frame(maxWidth: .infinity, minHeight: 44.0)
            }
            .disabled(isSaving)
            .buttonStyle(.mnemoPressable)

            Button(action: onDiscard) {
                Text("Discard")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 44.0)
            }
            .disabled(isSaving)
            .buttonStyle(.mnemoPressable)
        }
    }
}
