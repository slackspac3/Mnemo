import SwiftUI
import MnemoUI

/// Renders the correct content for each onboarding step.
struct OnboardingStepView: View {

    let step: OnboardingViewModel.Step
    let viewModel: OnboardingViewModel
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
            Spacer(minLength: DS.Spacing.sm)

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

            Spacer(minLength: DS.Spacing.sm)
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.md)
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
        case .done:
            DoneStepContent(viewModel: viewModel)
        }
    }

    private var iconColor: Color {
        switch step {
        case .welcome:
            return DS.Colours.brandInk
        case .notifications:
            return DS.Colours.accent
        case .done:
            return DS.Colours.success
        case .processingMode:
            return DS.Colours.accent
        }
    }

    @ViewBuilder
    private var stepMark: some View {
        switch step {
        case .welcome:
            MnemoLogoMark(size: 80.0, style: .filled)
        case .done:
            MnemoLogoMark(size: 72.0, style: .subtle)
        default:
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

struct ProtectionStepContent: View {
    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            OnboardingInfoCard(
                icon: "lock.open.fill",
                title: "Optional App Lock",
                description: "Unlock with Face ID, Touch ID or your passcode.",
                color: DS.Colours.accent
            )
            OnboardingInfoCard(
                icon: "person.crop.circle.badge.xmark",
                title: "No Mnemo account",
                description: "No email, password, or remote account is required.",
                color: DS.Colours.sense
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
                    .lineLimit(2)
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
