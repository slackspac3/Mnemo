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
            } else if !appState.onboardingComplete {
                PlaceholderOnboardingView()
            } else {
                ZStack {
                    PlaceholderMainView()

                    if appState.appLockEnabled && appState.isAppLocked {
                        AppLockView()
                            .transition(.opacity)
                    }
                }
            }
        }
        .animation(DS.Animation.standard, value: appState.isInitialised)
        .animation(DS.Animation.standard, value: appState.isAppLocked)
    }
}
