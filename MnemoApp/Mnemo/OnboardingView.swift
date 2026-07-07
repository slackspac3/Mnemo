import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore

/// Root onboarding container. Forward-only, V1 setup steps.
/// Gated: main app is inaccessible until complete.
struct OnboardingView: View {

    @State private var viewModel = OnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            DS.Colours.backgroundGrouped.ignoresSafeArea()

            VStack(spacing: DS.Spacing.xs) {
                OnboardingProgressBar(progress: viewModel.progress)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.lg)

                OnboardingStepView(
                    step: viewModel.currentStep,
                    viewModel: viewModel
                )
                .animation(reduceMotion ? DS.Animation.fade : DS.Animation.standard, value: viewModel.currentStep)

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    .animation(reduceMotion ? DS.Animation.fade : DS.Animation.standard, value: progress)
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
            case .capturePreference, .captureList, .captureCredential:
                HStack(spacing: DS.Spacing.sm) {
                    Button("Skip") {
                        HapticManager.selection()
                        viewModel.skipCapture()
                    }
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: DS.ComponentTokens.SecondaryButton.height)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Colours.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                            .stroke(DS.Colours.borderSubtle, lineWidth: 0.5)
                    }
                    .buttonStyle(.mnemoPressable)

                    Button {
                        Task {
                            await viewModel.confirmCapture(context: modelContext)
                        }
                    } label: {
                        Group {
                            if viewModel.isCapturing {
                                ProgressView()
                                    .tint(DS.ComponentTokens.PrimaryButton.foreground)
                            } else {
                                Text("Save & Continue")
                                    .font(DS.Typography.headline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(
                        viewModel.captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? DS.Colours.accentDisabled
                            : DS.ComponentTokens.PrimaryButton.background
                    )
                    .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                    .disabled(
                        viewModel.captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            viewModel.isCapturing
                    )
                    .buttonStyle(.mnemoPressable)
                }

            case .done:
                Button {
                    HapticManager.success()
                    viewModel.complete(context: modelContext, appState: appState)
                } label: {
                    Text("Start with one memory")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(DS.Colours.accent)
                        .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .buttonStyle(.mnemoPressable)
                .accessibilityIdentifier(AccessibilityID.Onboarding.completeButton)

            default:
                Button {
                    HapticManager.selection()
                    viewModel.advance()
                } label: {
                    Text("Continue")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(DS.Colours.accent)
                        .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .buttonStyle(.mnemoPressable)
                .accessibilityIdentifier(AccessibilityID.Onboarding.continueButton)
            }
        }
    }
}
