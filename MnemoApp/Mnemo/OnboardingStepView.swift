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
            RecallStepContent()
        case .notifications:
            ProtectionStepContent()
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
            return DS.Colours.accent
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
                text: "Saved memories stay on this iPhone unless you choose iCloud backup"
            )
            FeatureRow(
                icon: "person.crop.circle.badge.xmark",
                color: DS.Colours.sense,
                text: "No Mnemo account, email, or sign-in required"
            )
            FeatureRow(
                icon: "bookmark.fill",
                color: DS.Colours.success,
                text: "Every answer can show the saved memory it used"
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
                .accessibilityHidden(true)
            Text(text)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
            Spacer()
        }
    }
}

struct RecallStepContent: View {
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            OnboardingInfoCard(
                icon: "text.magnifyingglass",
                title: "Local recall",
                description: "Mnemo searches the memories you have saved and answers from that local store.",
                color: DS.Colours.accent
            )
            OnboardingInfoCard(
                icon: "bookmark.fill",
                title: "Sources stay visible",
                description: "When Mnemo recalls something, source cards show the memory behind the answer.",
                color: DS.Colours.success
            )
            OnboardingInfoCard(
                icon: "icloud.slash",
                title: "No cloud AI in this build",
                description: "Capture and recall stay local in this version. Future cloud processing would require a separate consent step.",
                color: DS.Colours.textSecondary
            )
        }
    }
}

struct ProtectionStepContent: View {
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            OnboardingInfoCard(
                icon: "lock.open.fill",
                title: "Optional App Lock",
                description: "Ask Mnemo to unlock with Face ID, Touch ID or your device passcode when you reopen the app.",
                color: DS.Colours.accent
            )
            OnboardingInfoCard(
                icon: "person.crop.circle.badge.xmark",
                title: "No account recovery step",
                description: "Mnemo does not create an account, password, or remote identity for V1.",
                color: DS.Colours.sense
            )
            OnboardingInfoCard(
                icon: "checkmark.shield.fill",
                title: "You stay in control",
                description: "Archive or permanently delete saved memories from the memory detail screen.",
                color: DS.Colours.success
            )
        }
    }
}

struct OnboardingInfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(DS.Typography.title2)
                .foregroundStyle(color)
                .frame(width: DS.Spacing.xl)
                .accessibilityHidden(true)

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
                    Text("Backup is optional and should be validated on your device before you rely on it for recovery.")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.Colours.textPrimary)
                    Text("The backup screen in Settings stores encrypted backup data in your iCloud account. Mnemo does not operate a backup server.")
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
                    .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                    .padding(.vertical, DS.Spacing.xs)
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
            Text("Save one detail now. Later, ask Mnemo in plain language and check the source memory it used.")
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
