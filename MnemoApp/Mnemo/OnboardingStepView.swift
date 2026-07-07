import SwiftUI
import MnemoUI

/// Renders the correct content for each onboarding step.
struct OnboardingStepView: View {

    let step: OnboardingViewModel.Step
    let viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                Spacer(minLength: DS.Spacing.xl)

                Image(systemName: step.icon)
                    .font(DS.Typography.largeTitle)
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: DS.Spacing.sm) {
                    Text(step.title)
                        .font(DS.Typography.title1)
                        .foregroundStyle(DS.Colours.primary)
                        .multilineTextAlignment(.center)

                    Text(step.subtitle)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.md)
                }

                stepContent

                Spacer(minLength: DS.Spacing.xxxl)
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            WelcomeStepContent()
        case .processingMode:
            ProcessingModeStepContent(viewModel: viewModel)
        case .notifications:
            NotificationsStepContent(viewModel: viewModel)
        case .backup:
            BackupStepContent(viewModel: viewModel)
        case .done:
            DoneStepContent(viewModel: viewModel)
        }
    }

    private var iconColor: Color {
        switch step {
        case .welcome:
            return DS.Colours.primary
        case .notifications:
            return DS.Colours.sense
        case .done:
            return DS.Colours.success
        case .processingMode, .backup:
            return DS.Colours.accent
        }
    }
}

struct WelcomeStepContent: View {
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            FeatureRow(
                icon: "lock.shield.fill",
                color: DS.Colours.accent,
                text: "Your memories are stored on this iPhone"
            )
            FeatureRow(
                icon: "magnifyingglass",
                color: DS.Colours.sense,
                text: "Recall uses your saved memory text"
            )
            FeatureRow(
                icon: "arrow.uturn.backward",
                color: DS.Colours.success,
                text: "Shows the source memory behind each answer"
            )
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
        .shadow(
            color: DS.Shadows.subtle.color,
            radius: DS.Shadows.subtle.radius,
            x: DS.Shadows.subtle.x,
            y: DS.Shadows.subtle.y
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(DS.Typography.title2)
                .foregroundStyle(color)
                .frame(width: DS.Spacing.xl)
            Text(text)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
            Spacer()
        }
    }
}

struct ProcessingModeStepContent: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ProcessingOptionCard(
                icon: "lock.shield.fill",
                title: "On-Device Only",
                description: "Memories are stored locally, and recall uses saved memory text on this iPhone. Recommended.",
                isSelected: viewModel.onDeviceOnly,
                color: DS.Colours.accent
            ) {
                viewModel.onDeviceOnly = true
            }

            ProcessingOptionCard(
                icon: "cloud.fill",
                title: "Future Cloud Assist",
                description: "Cloud Assist is a future opt-in route for ambiguous captures. In this build, captures stay on this device.",
                isSelected: !viewModel.onDeviceOnly,
                color: DS.Colours.textSecondary
            ) {
                viewModel.onDeviceOnly = false
            }

            if !viewModel.onDeviceOnly {
                AICloudConsentNotice()
            }
        }
    }
}

struct AICloudConsentNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Image(systemName: "info.circle")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.accent)
            Text("Cloud Assist is not connected to an external provider in this build. Future cloud processing will require explicit consent and can be changed in Settings.")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.textSecondary)
        }
        .padding(DS.Spacing.sm)
        .background(DS.Colours.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
    }
}

struct ProcessingOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: DS.Spacing.md) {
                Image(systemName: icon)
                    .font(DS.Typography.title2)
                    .foregroundStyle(color)
                    .frame(width: DS.Spacing.xl)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(title)
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colours.textPrimary)
                    Text(description)
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(DS.Typography.title2)
                    .foregroundStyle(isSelected ? DS.Colours.accent : DS.Colours.textTertiary)
            }
            .padding(DS.Spacing.md)
            .background(isSelected ? DS.Colours.surfaceSecondary : DS.Colours.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
            .selectedBorder(isSelected)
        }
        .shadow(
            color: DS.Shadows.subtle.color,
            radius: DS.Shadows.subtle.radius,
            x: DS.Shadows.subtle.x,
            y: DS.Shadows.subtle.y
        )
    }
}

struct NotificationsStepContent: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ProcessingOptionCard(
                icon: "bell.badge.fill",
                title: "Memory Moments are coming soon",
                description: "Smart reminders are not active in this build. They will stay off unless you explicitly turn them on later.",
                isSelected: false,
                color: DS.Colours.sense
            ) {
                viewModel.memoryMomentsEnabled = false
            }

            ProcessingOptionCard(
                icon: "bell.slash",
                title: "Keep reminders off",
                description: "Mnemo will not request notification permission during this setup.",
                isSelected: !viewModel.memoryMomentsEnabled,
                color: DS.Colours.textTertiary
            ) {
                viewModel.memoryMomentsEnabled = false
            }
        }
    }
}

struct BackupStepContent: View {
    let viewModel: OnboardingViewModel
    @State private var setupDeferred = false

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack(alignment: .top, spacing: DS.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.warning)
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Without a backup, if you lose your iPhone you lose your memories.")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.Colours.textPrimary)
                    Text("The backup screen in Settings performs the real encrypted iCloud backup flow.")
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.textSecondary)
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.Colours.warningLight)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))

            if setupDeferred {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.Colours.success)
                    Text("Backup setup left for Settings")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.Colours.success)
                }
            } else {
                Button {
                    setupDeferred = true
                    viewModel.backupDeferred = true
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "gearshape")
                            .font(DS.Typography.subheadline)
                        Text("Set Up Backup Later in Settings")
                            .font(DS.Typography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: DS.ComponentTokens.PrimaryButton.height)
                    .background(DS.Colours.accent)
                    .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }

                Button("Continue without backup") {
                    setupDeferred = true
                    viewModel.backupDeferred = true
                }
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
            }
        }
    }
}

struct DoneStepContent: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("The more you tell Mnemo, the more useful it becomes. Start capturing anything you want to remember.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

private extension View {
    @ViewBuilder
    func selectedBorder(_ isSelected: Bool) -> some View {
        if isSelected {
            overlay(
                RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                    .strokeBorder(DS.Colours.accent, lineWidth: DS.Spacing.xs / DS.Spacing.xs)
            )
        } else {
            self
        }
    }
}
