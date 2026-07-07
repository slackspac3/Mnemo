import SwiftUI
import MnemoUI

/// Local-only app lock gate. Uses the device authentication prompt through SecurityLayer.
struct AppLockView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            DS.Colours.appLockBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    VStack(spacing: DS.Spacing.md) {
                        MnemoLogoMark(size: 76.0, style: .filled)
                            .accessibilityHidden(true)

                        Text("Mnemo is locked")
                            .font(DS.Typography.title1)
                            .foregroundStyle(DS.Colours.textPrimary)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text("Use Face ID, Touch ID or your device passcode to unlock.")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colours.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Spacing.md)
                    }
                    .padding(DS.ComponentTokens.LockState.cardPadding)
                    .frame(maxWidth: 360.0)
                    .background(DS.Colours.appLockSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.CornerRadius.xlarge)
                            .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.xlarge))
                    .transition(DS.Animation.lockAppearTransition(reduceMotion: reduceMotion))

                    if let message = appState.appLockErrorMessage {
                        Text(message)
                            .font(DS.Typography.footnote)
                            .foregroundStyle(DS.Colours.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Spacing.lg)
                            .accessibilityLabel("App Lock error. \(message)")
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
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colours.textOnAccent)
                        .frame(maxWidth: 360.0)
                        .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(DS.Colours.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                    }
                    .disabled(appState.isAuthenticatingAppLock)
                    .buttonStyle(.mnemoPressable)
                    .accessibilityLabel("Unlock Mnemo")
                    .accessibilityHint("Use Face ID, Touch ID or your device passcode")
                    .accessibilityIdentifier(AccessibilityID.AppLock.unlockButton)

                    Text("No Mnemo account is required.")
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.vertical, DS.Spacing.xxxl)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .accessibilityIdentifier(AccessibilityID.AppLock.screen)
    }
}
