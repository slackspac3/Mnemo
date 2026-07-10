import SwiftUI
import SwiftData
import UIKit
import MnemoUI
import MnemoCore

/// Root onboarding container for Mnemo's private capture, recall, and source story.
/// Gated: main app is inaccessible until complete.
struct OnboardingView: View {

    @State private var viewModel = OnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            DS.Colours.backgroundGrouped.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressBar(
                    progress: viewModel.progress,
                    currentStep: viewModel.currentStep.rawValue + 1,
                    stepCount: OnboardingViewModel.Step.allCases.count
                )
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.lg)

                ScrollView {
                    OnboardingStepView(
                        step: viewModel.currentStep
                    )
                    .id(viewModel.currentStep)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .trailing)))
                }
                .scrollBounceBehavior(.basedOnSize)
                .animation(reduceMotion ? DS.Animation.fade : DS.Animation.standard, value: viewModel.currentStep)

                OnboardingNavigationBar(viewModel: viewModel)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.md)
                    .background(DS.Colours.backgroundGrouped)
            }
        }
        .environment(viewModel)
    }
}

struct OnboardingProgressBar: View {
    let progress: Double
    let currentStep: Int
    let stepCount: Int
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
        .accessibilityElement()
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Step \(currentStep) of \(stepCount)")
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

            ViewThatFits(in: .horizontal) {
                HStack(spacing: DS.Spacing.sm) {
                    navigationButtons
                }

                VStack(spacing: DS.Spacing.sm) {
                    navigationButtons
                }
            }
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        if viewModel.currentStep != .remember {
            Button {
                HapticManager.selection()
                viewModel.retreat()
                announceCurrentStep()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(.mnemoSecondary)
            .accessibilityIdentifier("onboarding.back")
        }

        Button {
            if viewModel.currentStep == .verify {
                HapticManager.success()
                viewModel.complete(context: modelContext, appState: appState)
            } else {
                HapticManager.selection()
                viewModel.advance()
                announceCurrentStep()
            }
        } label: {
            Text(viewModel.currentStep == .verify ? "Start Mnemo" : "Continue")
        }
        .buttonStyle(.mnemoPrimary)
        .accessibilityIdentifier(
            viewModel.currentStep == .verify
                ? AccessibilityID.Onboarding.completeButton
                : AccessibilityID.Onboarding.continueButton
        )
    }

    private func announceCurrentStep() {
        UIAccessibility.post(notification: .screenChanged, argument: viewModel.currentStep.title)
    }
}
