import Foundation
import SwiftUI
import SwiftData
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
                return "Your private memory layer"
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
