import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore

/// Root onboarding container. Forward-only, 8 steps.
/// Gated: main app is inaccessible until complete.
struct OnboardingView: View {

    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            DS.Colours.background.ignoresSafeArea()

            VStack(spacing: DS.Spacing.xs) {
                OnboardingProgressBar(progress: viewModel.progress)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.lg)

                OnboardingStepView(
                    step: viewModel.currentStep,
                    viewModel: viewModel
                )
                .animation(DS.Animation.standard, value: viewModel.currentStep)

                OnboardingNavigationBar(viewModel: viewModel)
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.bottom, DS.Spacing.xl)
            }
        }
        .environment(viewModel)
    }
}

struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: DS.CornerRadius.full)
                    .fill(DS.Colours.surfaceSecondary)
                    .frame(height: DS.Spacing.xs)

                RoundedRectangle(cornerRadius: DS.CornerRadius.full)
                    .fill(DS.Colours.accent)
                    .frame(
                        width: geometry.size.width * progress,
                        height: DS.Spacing.xs
                    )
                    .animation(DS.Animation.standard, value: progress)
            }
        }
        .frame(height: DS.Spacing.xs)
    }
}

struct OnboardingNavigationBar: View {

    let viewModel: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.destructive)
                    .multilineTextAlignment(.center)
            }

            switch viewModel.currentStep {
            case .done:
                Button {
                    viewModel.complete(context: modelContext, appState: appState)
                } label: {
                    Text("Start using Mnemo")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.ComponentTokens.PrimaryButton.height)
                        .background(DS.Colours.accent)
                        .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .accessibilityIdentifier(AccessibilityID.Onboarding.completeButton)

            default:
                Button {
                    viewModel.advance()
                } label: {
                    Text("Continue")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.ComponentTokens.PrimaryButton.height)
                        .background(DS.Colours.accent)
                        .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .accessibilityIdentifier(AccessibilityID.Onboarding.continueButton)
            }
        }
    }
}
