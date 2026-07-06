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
                PlaceholderMainView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isInitialised)
    }
}
