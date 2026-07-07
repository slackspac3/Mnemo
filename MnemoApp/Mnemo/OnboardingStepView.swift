import SwiftUI
import SwiftData
import MnemoUI

/// Renders the correct content for each onboarding step.
struct OnboardingStepView: View {

    let step: OnboardingViewModel.Step
    let viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                Spacer(minLength: DS.Spacing.xl)

                ZStack {
                    MnemoThreadMotif(style: .hero, lineWidth: 2.0)
                        .frame(width: 144.0, height: 112.0)
                    stepMark
                }
                .onboardingStaggered(appeared: contentAppeared, delay: 0.0, reduceMotion: reduceMotion)

                VStack(spacing: DS.Spacing.sm) {
                    Text(step.title)
                        .font(DS.Typography.title1)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .multilineTextAlignment(.center)
                        .onboardingStaggered(appeared: contentAppeared, delay: 0.08, reduceMotion: reduceMotion)

                    Text(step.subtitle)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.md)
                        .onboardingStaggered(appeared: contentAppeared, delay: 0.14, reduceMotion: reduceMotion)
                }

                stepContent
                    .onboardingStaggered(appeared: contentAppeared, delay: 0.22, reduceMotion: reduceMotion)

                Spacer(minLength: DS.Spacing.xxxl)
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            revealContent()
        }
        .onChange(of: step.rawValue) {
            contentAppeared = false
            revealContent()
        }
        .onDisappear {
            contentAppeared = false
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            WelcomeStepContent()
        case .capturePreference, .captureList, .captureCredential:
            CaptureOnboardingStepContent(
                placeholder: capturePlaceholder(for: step),
                viewModel: viewModel
            )
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
            return DS.Colours.brandInk
        case .capturePreference:
            return DS.Colours.sense
        case .captureList:
            return DS.Colours.success
        case .captureCredential:
            return DS.Colours.warning
        case .notifications:
            return DS.Colours.accent
        case .done:
            return DS.Colours.success
        case .processingMode, .backup:
            return DS.Colours.accent
        }
    }

    @ViewBuilder
    private var stepMark: some View {
        switch step {
        case .welcome:
            MnemoLogoMark(size: 88.0, style: .filled)
        case .done:
            MnemoLogoMark(size: 76.0, style: .subtle)
        default:
            Image(systemName: step.icon)
                .font(DS.Typography.largeTitle)
                .foregroundStyle(iconColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 88.0, height: 88.0)
                .background(DS.Colours.privateBadgeSurface)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.xlarge, style: .continuous))
                .accessibilityHidden(true)
        }
    }

    private func revealContent() {
        withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.gentleSpring) {
            contentAppeared = true
        }
    }

    private func capturePlaceholder(for step: OnboardingViewModel.Step) -> String {
        switch step {
        case .capturePreference:
            return "e.g. I wear a medium at Zara"
        case .captureList:
            return "e.g. oat milk, bin bags, parmesan"
        case .captureCredential:
            return "e.g. My Boots card number is 1234"
        default:
            return "Tell Mnemo something..."
        }
    }
}

struct WelcomeStepContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let features: [(icon: String, color: Color, text: String)] = [
        (
            icon: "lock.shield.fill",
            color: DS.Colours.accent,
            text: "Saved memories stay on this iPhone unless you choose iCloud backup"
        ),
        (
            icon: "person.crop.circle.badge.xmark",
            color: DS.Colours.sense,
            text: "No Mnemo account, email, or sign-in required"
        ),
        (
            icon: "bookmark.fill",
            color: DS.Colours.success,
            text: "Every answer can show the saved memory it used"
        ),
    ]

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                FeatureRow(
                    icon: feature.icon,
                    color: feature.color,
                    text: feature.text
                )
                .onboardingStaggered(
                    appeared: appeared,
                    delay: Double(index) * 0.06,
                    reduceMotion: reduceMotion
                )
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.memoryCardSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
        .shadow(
            color: DS.Shadows.subtle.color,
            radius: DS.Shadows.subtle.radius,
            x: DS.Shadows.subtle.x,
            y: DS.Shadows.subtle.y
        )
        .onAppear {
            withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.gentleSpring) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
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
                .frame(width: 40.0, height: 40.0)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.small))
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
        .background(DS.Colours.memoryCardSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
        }
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
            .background(DS.Colours.warningSoft)
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
                .buttonStyle(.mnemoPressable)

                Button("Continue without backup") {
                    setupDeferred = true
                    viewModel.backupDeferred = true
                }
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
                .buttonStyle(.mnemoPressable)
            }
        }
    }
}

struct DoneStepContent: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            if viewModel.seededCount > 0 {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.Colours.success)
                    Text(viewModel.seededCount == 1
                        ? "1 memory saved. Ask Mnemo about it in Chat."
                        : "\(viewModel.seededCount) memories saved. Ask Mnemo about them in Chat."
                    )
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textPrimary)
                }
                .padding(DS.Spacing.md)
                .background(DS.Colours.successSoft)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
            }

            Text("Save one detail now. Later, ask Mnemo in plain language and check the source memory it used.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct CaptureOnboardingStepContent: View {
    let placeholder: String
    let viewModel: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: DS.Spacing.md) {
            TextField(placeholder, text: $viewModel.captureText, axis: .vertical)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
                .lineLimit(2...5)
                .padding(DS.Spacing.md)
                .background(DS.Colours.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                        .stroke(DS.Colours.borderSubtle, lineWidth: 0.5)
                }

            if viewModel.captureConfirmed {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.Colours.success)
                        .font(DS.Typography.subheadline)
                    Text("Saved to Mnemo")
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.success)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.destructive)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private extension View {
    func onboardingStaggered(appeared: Bool, delay: Double, reduceMotion: Bool) -> some View {
        opacity(appeared ? 1.0 : 0.0)
            .offset(y: reduceMotion || appeared ? 0.0 : 12.0)
            .animation(
                reduceMotion
                    ? DS.Animation.fade
                    : DS.Animation.gentleSpring.delay(delay),
                value: appeared
            )
    }

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
