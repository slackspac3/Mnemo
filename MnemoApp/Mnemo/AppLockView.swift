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
                        .foregroundStyle(DS.Colours.accent)

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
                            Image(systemName: "faceid")
                        }
                        Text(appState.isAuthenticatingAppLock ? "Unlocking..." : "Unlock")
                    }
                    .font(DS.Typography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
                    .background(DS.Colours.accent)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .disabled(appState.isAuthenticatingAppLock)
                .padding(.horizontal, DS.Spacing.xl)
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
