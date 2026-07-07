import SwiftUI
import MnemoUI

/// Shown while AppState initialises on launch.
struct SplashView: View {
    var body: some View {
        ZStack {
            DS.Colours.backgroundGrouped.ignoresSafeArea()
            VStack(spacing: DS.Spacing.lg) {
                MnemoLogoMark(size: 88.0, style: .filled)

                Text("Mnemo")
                    .font(DS.Typography.largeTitle)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("remembering what matters")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
        }
    }
}
