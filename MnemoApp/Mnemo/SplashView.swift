import SwiftUI
import MnemoUI

/// Shown while AppState initialises on launch.
struct SplashView: View {
    var body: some View {
        ZStack {
            DS.Colours.backgroundGrouped.ignoresSafeArea()

            MnemoBrandLockup(markSize: 52.0)
        }
    }
}
