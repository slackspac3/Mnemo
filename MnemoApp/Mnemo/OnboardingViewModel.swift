import Foundation
import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoCapture
import MnemoIntelligence
import MnemoMemory

/// State machine for the privacy-first onboarding flow.
/// Forward-only navigation: no back button.
/// Completion sets UserModel.onboardingComplete = true and dismisses onboarding.
@Observable
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case welcome = 0
        case capturePreference = 1
        case captureList = 2
        case captureCredential = 3
        case processingMode = 4
        case notifications = 5
        case backup = 6
        case done = 7

        var title: String {
            switch self {
            case .welcome:
                return "Your private memory layer"
            case .capturePreference:
                return "Tell Mnemo something"
            case .captureList:
                return "What do you forget?"
            case .captureCredential:
                return "A number you look up"
            case .processingMode:
                return "Ask what you saved"
            case .notifications:
                return "Protected by your device"
            case .backup:
                return "Backup is optional"
            case .done:
                return "Start with one memory"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome:
                return "Save the details, decisions, and reminders you do not want to lose. Mnemo keeps them organised on your iPhone."
            case .capturePreference:
                return "What size do you wear most often? A brand, a style — anything you always have to look up."
            case .captureList:
                return "What do you always forget to buy, or need to be reminded about?"
            case .captureCredential:
                return "A membership number, a reference code, or anything you wish you had saved."
            case .processingMode:
                return "Ask in plain language. Mnemo answers from saved memories and shows the source it used."
            case .notifications:
                return "Use App Lock with Face ID, Touch ID or your device passcode. No Mnemo account is required."
            case .backup:
                return "You can set up iCloud backup from Settings after validating it on your device."
            case .done:
                return "Begin by saving one thing you want Mnemo to remember."
            }
        }

        var icon: String {
            switch self {
            case .welcome:
                return "lock.doc.fill"
            case .capturePreference:
                return "heart.fill"
            case .captureList:
                return "checklist"
            case .captureCredential:
                return "key.fill"
            case .processingMode:
                return "quote.bubble.fill"
            case .notifications:
                return "lock.shield.fill"
            case .backup:
                return "icloud.fill"
            case .done:
                return "checkmark.circle.fill"
            }
        }
    }

    var currentStep: Step = .welcome
    var onDeviceOnly = true
    var memoryMomentsEnabled = false
    var backupDeferred = false
    var errorMessage: String?
    var captureText: String = ""
    var isCapturing: Bool = false
    var captureConfirmed: Bool = false
    var seededCount: Int = 0

    var progress: Double {
        Double(currentStep.rawValue) / Double(Step.allCases.count - 1)
    }

    func advance() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }

        withAnimation(DS.Animation.standard) {
            errorMessage = nil
            if [Step.capturePreference, .captureList, .captureCredential].contains(currentStep) {
                captureText = ""
                captureConfirmed = false
            }
            currentStep = nextStep
        }
    }

    func skipCapture() {
        captureText = ""
        captureConfirmed = false
        errorMessage = nil
        advance()
    }

    @MainActor
    func confirmCapture(context: ModelContext) async {
        let trimmed = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            advance()
            return
        }

        isCapturing = true
        errorMessage = nil

        do {
            let handler = TextCaptureHandler()
            let capture = try handler.capture(text: trimmed)
            let engine = ExtractionEngine()
            let result = try await engine.extract(
                rawText: capture.text,
                source: .text,
                threshold: 0.90
            )
            let record = MemoryRecord(
                rawInput: trimmed,
                summary: result.summary,
                memoryType: result.memoryType,
                persistenceScore: result.persistenceScore,
                inputSource: .text,
                processingTier: result.processingTier,
                modalityThresholdUsed: result.modalityThresholdUsed,
                confidence: result.confidence,
                tags: result.tags
            )
            try await MemoryCRUD.insertAndIndex(record, into: context)
            seededCount += 1
            captureText = ""
            captureConfirmed = true
            errorMessage = nil
            HapticManager.success()
        } catch {
            errorMessage = "Could not save that. Try typing it differently."
            HapticManager.error()
        }

        isCapturing = false
        advance()
    }

    @MainActor
    func complete(context: ModelContext, appState: AppState) {
        let descriptor = FetchDescriptor<UserModel>()
        let existing = try? context.fetch(descriptor)

        let userModel: UserModel
        if let first = existing?.first {
            userModel = first
        } else {
            userModel = UserModel()
            context.insert(userModel)
        }

        userModel.onboardingComplete = true
        userModel.onDeviceOnly = onDeviceOnly
        userModel.cloudFallbackEnabled = false
        userModel.memoryMomentsEnabled = memoryMomentsEnabled
        try? context.save()

        appState.onboardingComplete = true
    }
}
