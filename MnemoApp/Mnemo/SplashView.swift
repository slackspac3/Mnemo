import SwiftUI
import UIKit
import MnemoUI

/// Shown while AppState initialises on launch.
struct SplashView: View {
    var body: some View {
        ZStack {
            // Match the generated system launch screen; the Sage canvas appears with real app content.
            Color(uiColor: .systemBackground).ignoresSafeArea()

            MnemoBrandLockup(markSize: 52.0)
        }
    }
}
