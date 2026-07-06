import SwiftUI
import MnemoUI

/// Placeholder until Phase 11 builds the real onboarding flow.
struct PlaceholderOnboardingView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            DS.Colours.background.ignoresSafeArea()
            VStack(spacing: DS.Spacing.xl) {
                Text("Welcome to Mnemo")
                    .font(DS.Typography.title1)
                    .foregroundStyle(DS.Colours.primary)
                Text("Onboarding coming in Phase 11")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
                Button("Skip to App (Dev Only)") {
                    appState.onboardingComplete = true
                }
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colours.accent)
                .padding(DS.Spacing.md)
                .background(DS.Colours.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }
            .padding(DS.Spacing.xl)
        }
    }
}
