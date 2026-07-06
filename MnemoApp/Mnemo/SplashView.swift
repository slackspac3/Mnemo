import SwiftUI
import MnemoUI

/// Shown while AppState initialises on launch.
struct SplashView: View {
    var body: some View {
        ZStack {
            DS.Colours.background.ignoresSafeArea()
            VStack(spacing: DS.Spacing.lg) {
                Text("mnemo")
                    .font(DS.Typography.largeTitle)
                    .foregroundStyle(DS.Colours.primary)
                Text("remembering what matters")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
        }
    }
}
