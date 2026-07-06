import SwiftUI
import MnemoUI
import MnemoCore

/// Placeholder main interface until Phase 8 builds the real UI.
struct PlaceholderMainView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            DS.Colours.background.ignoresSafeArea()
            VStack(spacing: DS.Spacing.lg) {
                Text("Mnemo")
                    .font(DS.Typography.title1)
                    .foregroundStyle(DS.Colours.primary)

                Text("Device tier: \(appState.deviceCapability.tier.rawValue)")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.textSecondary)

                VStack(spacing: DS.Spacing.sm) {
                    Text("Phase 7 scaffold complete")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colours.textPrimary)
                    Text("UI modules build in Phase 8")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                }
                .padding(DS.Spacing.lg)
                .background(DS.Colours.surface)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

                // Sense badge to verify DesignSystem
                Text("Mnemo Sense")
                    .font(DS.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Colours.sense)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Colours.senseLight)
                    .clipShape(Capsule())
            }
            .padding(DS.Spacing.xl)
        }
    }
}
