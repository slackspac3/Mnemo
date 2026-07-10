import SwiftUI
import MnemoUI

/// Shown while AppState initialises on launch.
struct SplashView: View {
    var body: some View {
        ZStack {
            DS.Colours.canvas.ignoresSafeArea()

            MnemoLogoMark(size: 72.0, style: .filled)
                .accessibilityLabel("Mnemo")
        }
    }
}
