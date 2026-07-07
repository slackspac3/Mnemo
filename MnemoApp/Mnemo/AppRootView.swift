import SwiftUI
import MnemoUI
import MnemoCore

/// Root view that switches between onboarding and main app.
struct AppRootView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if !appState.isInitialised {
                SplashView()
                    .accessibilityIdentifier("root.splash")
            } else if !appState.onboardingComplete {
                OnboardingView()
                    .accessibilityIdentifier("root.onboarding")
            } else if appState.appLockEnabled && appState.isAppLocked {
                AppLockView()
                    .accessibilityIdentifier("root.locked")
            } else if appState.isPrivacyShieldVisible {
                PrivacyShieldView()
                    .accessibilityIdentifier("root.privacyShield")
            } else {
                MainTabView()
                    .accessibilityIdentifier("root.main")
            }
        }
        .animation(reduceMotion ? DS.Animation.fade : DS.Animation.standard, value: appState.isInitialised)
        .animation(reduceMotion ? DS.Animation.fade : DS.Animation.standard, value: appState.isAppLocked)
        .animation(reduceMotion ? DS.Animation.fade : DS.Animation.standard, value: appState.isPrivacyShieldVisible)
    }
}

private struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            DS.Colours.appLockBackground.ignoresSafeArea()

            VStack(spacing: DS.Spacing.md) {
                MnemoLogoMark(size: 72.0, style: .filled)
                    .accessibilityHidden(true)

                Text("Mnemo is private")
                    .font(DS.Typography.title2)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(DS.Spacing.xl)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mnemo is private")
    }
}
