import Foundation
import SwiftUI
import SwiftData
import UserNotifications
import MnemoUI
import MnemoCore
import MnemoMemory

/// State machine for the privacy-first onboarding flow.
/// Forward-only navigation: no back button.
/// Completion sets UserModel.onboardingComplete = true and dismisses onboarding.
@Observable
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case welcome = 0
        case processingMode = 1
        case notifications = 2
        case backup = 3
        case done = 4

        var title: String {
            switch self {
            case .welcome:
                return "Welcome to Mnemo"
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
            case .processingMode:
                return "Mnemo processes everything on your device by default. Nothing leaves your iPhone unless you say so."
            case .notifications:
                return "Smart reminders are being prepared. They stay off in this build."
            case .backup:
                return "Your memories live on your device. Set up iCloud backup from Settings when you are ready."
            case .done:
                return "Mnemo is ready. Save memories now, then ask for them later."
            }
        }

        var icon: String {
            switch self {
            case .welcome:
                return "brain.head.profile"
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
    var onDeviceOnly = true
    var memoryMomentsEnabled = false
    var backupDeferred = false
    var errorMessage: String?

    var progress: Double {
        Double(currentStep.rawValue) / Double(Step.allCases.count - 1)
    }

    func advance() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }

        withAnimation(DS.Animation.standard) {
            errorMessage = nil
            currentStep = nextStep
        }
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
