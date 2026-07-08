import SwiftUI
import MnemoUI

/// Shown while AppState initialises on launch.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = true

    var body: some View {
        ZStack {
            DS.Colours.backgroundGrouped.ignoresSafeArea()
            VStack(spacing: DS.Spacing.lg) {
                ZStack {
                    MnemoThreadMotif(style: .hero, lineWidth: 2.4)
                        .frame(width: 180.0, height: 140.0)
                    MnemoLogoMark(size: 88.0, style: .filled)
                }

                Text("Mnemo")
                    .font(DS.Typography.largeTitle)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("Remember what matters")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
            .opacity(appeared ? 1.0 : 0.0)
            .scaleEffect(reduceMotion ? 1.0 : (appeared ? 1.0 : 0.98))
            .onAppear {
                guard !appeared else { return }
                withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.heroAppear) {
                    appeared = true
                }
            }
        }
    }
}
