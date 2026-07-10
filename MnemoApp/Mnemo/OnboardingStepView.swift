import SwiftUI
import MnemoUI

/// Renders the correct content for each onboarding step.
struct OnboardingStepView: View {

    let step: OnboardingViewModel.Step
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentAppeared = false

    var body: some View {
        onboardingContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    private var onboardingContent: some View {
        VStack(spacing: DS.Spacing.lg) {
            ZStack {
                MnemoThreadMotif(style: .hero, lineWidth: 2.0)
                    .frame(width: 128.0, height: 96.0)
                stepMark
            }
            .onboardingStaggered(appeared: contentAppeared, delay: 0.0, reduceMotion: reduceMotion)

            VStack(spacing: DS.Spacing.xs) {
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

        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.md)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .remember:
            WelcomeStepContent()
        case .ask:
            RecallStepContent()
        case .verify:
            VerificationStepContent()
        }
    }

    private var iconColor: Color {
        switch step {
        case .remember:
            return DS.Colours.brandInk
        case .ask, .verify:
            return DS.Colours.accent
        }
    }

    @ViewBuilder
    private var stepMark: some View {
        switch step {
        case .remember:
            MnemoLogoMark(size: 80.0, style: .filled)
        case .ask, .verify:
            Image(systemName: step.icon)
                .font(DS.Typography.title1)
                .foregroundStyle(iconColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 76.0, height: 76.0)
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
}

struct WelcomeStepContent: View {
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
            icon: "lock.open.fill",
            color: DS.Colours.accent,
            text: "Optional App Lock uses Face ID, Touch ID, or your passcode"
        ),
    ]

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                FeatureRow(
                    icon: feature.icon,
                    color: feature.color,
                    text: feature.text
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
                .frame(width: 44.0, height: 44.0)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                .accessibilityHidden(true)
            Text(text)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
            Spacer()
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

struct RecallStepContent: View {
    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            OnboardingInfoCard(
                icon: "text.magnifyingglass",
                title: "Local recall",
                description: "Mnemo answers from memories saved on this iPhone.",
                color: DS.Colours.accent
            )
            OnboardingInfoCard(
                icon: "bookmark.fill",
                title: "Sources stay visible",
                description: "Source cards show the memory behind an answer.",
                color: DS.Colours.success
            )
        }
    }
}

struct VerificationStepContent: View {
    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            OnboardingInfoCard(
                icon: "bookmark.fill",
                title: "Source cards",
                description: "Open the saved memory behind an answer.",
                color: DS.Colours.accent
            )
            OnboardingInfoCard(
                icon: "lock.shield.fill",
                title: "You stay in control",
                description: "Use optional App Lock, archive memories, or delete them permanently.",
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
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
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
    }
}

private extension View {
    func onboardingStaggered(appeared: Bool, delay: Double, reduceMotion: Bool) -> some View {
        opacity(appeared ? 1.0 : 0.0)
            .offset(y: reduceMotion || appeared ? 0.0 : 12.0)
            .animation(
                reduceMotion
                    ? DS.Animation.fade
                    : DS.Animation.standard.delay(min(delay, 0.08)),
                value: appeared
            )
    }
}
