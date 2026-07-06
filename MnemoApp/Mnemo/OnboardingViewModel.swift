import Foundation
import SwiftUI
import SwiftData
import UserNotifications
import MnemoUI
import MnemoCore
import MnemoMemory
import MnemoCapture
import MnemoIntelligence

/// State machine for the 8-step onboarding flow.
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
                return "Welcome to Mnemo"
            case .capturePreference:
                return "Tell me something"
            case .captureList:
                return "What do you forget?"
            case .captureCredential:
                return "A number you look up"
            case .processingMode:
                return "Your Privacy"
            case .notifications:
                return "Memory Moments"
            case .backup:
                return "Keep it safe"
            case .done:
                return "You're all set"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome:
                return "A private memory companion for your iPhone. Everything stays on your device."
            case .capturePreference:
                return "What size do you wear most often? A brand, a style - anything you always have to think about."
            case .captureList:
                return "What do you always forget to buy? Mnemo will remind you before you get to the shop."
            case .captureCredential:
                return "A membership number, a reference code, a PIN you always have to look up."
            case .processingMode:
                return "Mnemo processes everything on your device by default. Nothing leaves your iPhone unless you say so."
            case .notifications:
                return "Once a week, Mnemo can surface something you've forgotten about - at the right moment."
            case .backup:
                return "Your memories live on your device. Back them up to iCloud so you never lose them."
            case .done:
                return "Mnemo is ready. The more you tell it, the more useful it becomes."
            }
        }

        var icon: String {
            switch self {
            case .welcome:
                return "brain.head.profile"
            case .capturePreference:
                return "heart.fill"
            case .captureList:
                return "checklist"
            case .captureCredential:
                return "key.fill"
            case .processingMode:
                return "lock.shield.fill"
            case .notifications:
                return "bell.badge"
            case .backup:
                return "icloud.fill"
            case .done:
                return "checkmark.circle.fill"
            }
        }
    }

    var currentStep: Step = .welcome
    var captureText = ""
    var isCapturing = false
    var captureConfirmed = false
    var onDeviceOnly = true
    var memoryMomentsEnabled = false
    var backupDeferred = false
    var errorMessage: String?

    var seededMemories: [String] = []

    var progress: Double {
        Double(currentStep.rawValue) / Double(Step.allCases.count - 1)
    }

    var isLastCaptureStep: Bool {
        currentStep == .captureCredential
    }

    var canAdvance: Bool {
        switch currentStep {
        case .capturePreference, .captureList, .captureCredential:
            return captureConfirmed || !captureText.isEmpty
        default:
            return true
        }
    }

    func advance() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }

        withAnimation(DS.Animation.standard) {
            captureText = ""
            captureConfirmed = false
            errorMessage = nil
            currentStep = nextStep
        }
    }

    func skipCapture() {
        captureText = ""
        captureConfirmed = false
        advance()
    }

    @MainActor
    func confirmCapture(context: ModelContext) async {
        guard !captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            advance()
            return
        }

        isCapturing = true
        defer { isCapturing = false }

        let engine = ExtractionEngine()
        do {
            let handler = TextCaptureHandler()
            let capture = try handler.capture(text: captureText)
            let result = try await engine.extract(
                rawText: capture.text,
                source: .text,
                threshold: 0.90
            )

            let record = MemoryRecord(
                rawInput: capture.text,
                summary: result.summary,
                memoryType: result.memoryType,
                persistenceScore: result.persistenceScore,
                inputSource: .text,
                processingTier: result.processingTier,
                modalityThresholdUsed: result.modalityThresholdUsed,
                confidence: result.confidence,
                tags: result.tags
            )
            context.insert(record)
            try context.save()

            seededMemories.append(result.summary)
            captureConfirmed = true
            errorMessage = nil
        } catch {
            errorMessage = "Could not save that. Try typing it differently."
            return
        }

        advance()
    }

    @MainActor
    func requestMemoryMomentsPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
                await MainActor.run {
                    memoryMomentsEnabled = granted
                    errorMessage = granted ? nil : "Notifications were not enabled. You can turn them on later in Settings."
                }
            } catch {
                await MainActor.run {
                    memoryMomentsEnabled = false
                    errorMessage = "Notifications were not enabled. You can turn them on later in Settings."
                }
            }
        }
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
        userModel.cloudFallbackEnabled = !onDeviceOnly
        userModel.memoryMomentsEnabled = memoryMomentsEnabled
        try? context.save()

        appState.onboardingComplete = true
    }
}
