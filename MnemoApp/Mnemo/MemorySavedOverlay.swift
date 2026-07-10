import SwiftUI
import UIKit
import MnemoUI

struct MemorySavedOverlay: View {
    let summary: String
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var isAccessibilityFocused: Bool
    @State private var isVisible = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    VStack(spacing: DS.Spacing.lg) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(DS.Typography.largeTitle.weight(.semibold))
                            .imageScale(.large)
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
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Memory saved")
                    .accessibilityValue(summary)
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityFocused($isAccessibilityFocused)

                    if needsManualDismissal {
                        Button("Done") {
                            onDismiss()
                        }
                        .buttonStyle(.mnemoPrimary)
                        .frame(maxWidth: 320.0)
                        .accessibilityHint("Return to Mnemo")
                    }
                }
                .padding(DS.Spacing.xl)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colours.backgroundGrouped)
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(reduceMotion ? 1.0 : (isVisible ? 1.0 : 0.96))
        .onAppear {
            withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.emphasisSpring) {
                isVisible = true
            }
            isAccessibilityFocused = true
        }
        .task {
            await dismissAutomaticallyIfAppropriate()
        }
        .accessibilityAction(.escape, onDismiss)
    }

    private var needsManualDismissal: Bool {
        UIAccessibility.isVoiceOverRunning
            || UIAccessibility.isSwitchControlRunning
            || dynamicTypeSize.isAccessibilitySize
    }

    @MainActor
    private func dismissAutomaticallyIfAppropriate() async {
        guard !needsManualDismissal else { return }
        do {
            try await Task.sleep(nanoseconds: 1_800_000_000)
            try Task.checkCancellation()
            withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.emphasisSpring) {
                isVisible = false
            }
            try await Task.sleep(nanoseconds: 180_000_000)
            try Task.checkCancellation()
            onDismiss()
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }
}
