import SwiftUI
import MnemoUI

struct MemorySavedOverlay: View {
    let summary: String
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64.0, weight: .semibold))
                .foregroundStyle(DS.Colours.success)
                .accessibilityHidden(true)

            Text("Saved to Mnemo")
                .font(DS.Typography.title2)
                .foregroundStyle(DS.Colours.textPrimary)
                .multilineTextAlignment(.center)

            Text(summary)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .padding(.horizontal, DS.Spacing.lg)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colours.backgroundGrouped)
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(reduceMotion ? 1.0 : (isVisible ? 1.0 : 0.7))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Memory saved")
        .accessibilityValue(summary)
        .onAppear {
            showThenDismiss()
        }
    }

    private func showThenDismiss() {
        withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.emphasisSpring) {
            isVisible = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.emphasisSpring) {
                isVisible = false
            }
            try? await Task.sleep(nanoseconds: 180_000_000)
            onDismiss()
        }
    }
}
