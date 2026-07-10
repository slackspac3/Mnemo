import Foundation
import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// State machine for the privacy-first onboarding flow.
/// Completion sets UserModel.onboardingComplete = true and dismisses onboarding.
@Observable
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case remember = 0
        case ask = 1
        case verify = 2

        var title: String {
            switch self {
            case .remember:
                return "Remember privately"
            case .ask:
                return "Ask naturally"
            case .verify:
                return "See the source"
            }
        }

        var subtitle: String {
            switch self {
            case .remember:
                return "Save details, decisions and reminders on your iPhone. No account or server is required."
            case .ask:
                return "Ask in plain language. Mnemo recalls from the memories you chose to save."
            case .verify:
                return "Open the source behind an answer, then archive or delete memories when you choose."
            }
        }

        var icon: String {
            switch self {
            case .remember:
                return "lock.doc.fill"
            case .ask:
                return "quote.bubble.fill"
            case .verify:
                return "bookmark.fill"
            }
        }
    }

    var currentStep: Step = .remember
    var onDeviceOnly = true
    var memoryMomentsEnabled = false
    var errorMessage: String?

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    func advance() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }

        errorMessage = nil
        currentStep = nextStep
    }

    func retreat() {
        guard let previousStep = Step(rawValue: currentStep.rawValue - 1) else { return }
        errorMessage = nil
        currentStep = previousStep
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
