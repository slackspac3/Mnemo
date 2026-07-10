import SwiftUI
import UIKit
import MnemoUI

/// Local-only app lock gate. Uses the device authentication prompt through SecurityLayer.
struct AppLockView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var isErrorFocused: Bool

    var body: some View {
        ZStack {
            DS.Colours.appLockBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    MnemoLogoMark(size: 76.0, style: .filled)
                        .accessibilityHidden(true)

                    VStack(spacing: DS.Spacing.sm) {
                        Text("Mnemo is locked")
                            .font(DS.Typography.title1)
                            .foregroundStyle(DS.Colours.textPrimary)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text("Unlock with Face ID, Touch ID, or your device passcode.")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colours.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: 320.0)
                    .transition(DS.Animation.lockAppearTransition(reduceMotion: reduceMotion))

                    if let message = appState.appLockErrorMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .font(DS.Typography.footnote)
                            .foregroundStyle(DS.Colours.destructive)
                            .multilineTextAlignment(.leading)
                            .padding(DS.Spacing.md)
                            .frame(maxWidth: 360.0, alignment: .leading)
                            .background(DS.Colours.destructiveSoft)
                            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                            .accessibilityLabel("App Lock error. \(message)")
                            .accessibilityFocused($isErrorFocused)
                            .accessibilityIdentifier(AccessibilityID.AppLock.errorMessage)
                    }

                    Button {
                        Task {
                            await appState.unlockApp()
                        }
                    } label: {
                        HStack(spacing: DS.Spacing.sm) {
                            if appState.isAuthenticatingAppLock {
                                ProgressView()
                                    .tint(DS.Colours.textOnAccent)
                            } else {
                                Image(systemName: "lock.open.fill")
                            }
                            Text(appState.isAuthenticatingAppLock ? "Unlocking..." : "Unlock")
                        }
                    }
                    .disabled(appState.isAuthenticatingAppLock)
                    .buttonStyle(.mnemoPrimary)
                    .frame(maxWidth: 360.0)
                    .accessibilityLabel("Unlock Mnemo")
                    .accessibilityHint("Use Face ID, Touch ID or your device passcode")
                    .accessibilityIdentifier(AccessibilityID.AppLock.unlockButton)

                    Label("Protected on this device", systemImage: "lock.shield")
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.textSecondary)
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.vertical, DS.Spacing.xxl)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onChange(of: appState.appLockErrorMessage) { _, message in
            guard message != nil else { return }
            isErrorFocused = true
        }
        .accessibilityIdentifier(AccessibilityID.AppLock.screen)
    }
}
