import SwiftUI
import MnemoUI
import MnemoCore

/// Root view that switches between onboarding and main app.
struct AppRootView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if !appState.isInitialised {
                SplashView()
                    .accessibilityIdentifier("root.splash")
            } else if !appState.onboardingComplete {
                PlaceholderOnboardingView()
                    .accessibilityIdentifier("root.onboarding")
            } else if appState.appLockEnabled && appState.isAppLocked {
                AppLockView()
                    .accessibilityIdentifier("root.locked")
            } else {
                PlaceholderMainView()
                    .accessibilityIdentifier("root.main")
            }
        }
        .animation(DS.Animation.standard, value: appState.isInitialised)
    }
}
