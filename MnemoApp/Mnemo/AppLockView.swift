import SwiftUI
import MnemoUI

/// Local-only app lock gate. Uses the device authentication prompt through SecurityLayer.
struct AppLockView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            DS.Colours.background.ignoresSafeArea()

            VStack(spacing: DS.Spacing.xl) {
                Spacer()

                VStack(spacing: DS.Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(DS.ComponentTokens.LockState.iconForeground)
                        .frame(width: 96.0, height: 96.0)
                        .background(DS.ComponentTokens.LockState.iconBackground)
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    Text("Mnemo is locked")
                        .font(DS.Typography.largeTitle)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Use Face ID, Touch ID or your device passcode to unlock.")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.lg)
                }
                .padding(DS.ComponentTokens.LockState.cardPadding)
                .frame(maxWidth: 360.0)
                .background(DS.Colours.surface)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.xlarge))
                .shadow(
                    color: DS.Shadows.subtle.color,
                    radius: DS.Shadows.subtle.radius,
                    x: DS.Shadows.subtle.x,
                    y: DS.Shadows.subtle.y
                )

                if let message = appState.appLockErrorMessage {
                    Text(message)
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.destructive)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.lg)
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
                                .tint(.white)
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text(appState.isAuthenticatingAppLock ? "Unlocking..." : "Unlock")
                    }
                    .font(DS.Typography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Colours.accent)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .disabled(appState.isAuthenticatingAppLock)
                .padding(.horizontal, DS.Spacing.xl)
                .accessibilityLabel("Unlock Mnemo")
                .accessibilityHint("Use Face ID, Touch ID or your device passcode")
                .accessibilityIdentifier(AccessibilityID.AppLock.unlockButton)

                Spacer()

                Text("No Mnemo account is required.")
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colours.textTertiary)
                    .padding(.bottom, DS.Spacing.lg)
            }
        }
        .accessibilityIdentifier(AccessibilityID.AppLock.screen)
    }
}
