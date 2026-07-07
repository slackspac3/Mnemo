import Foundation
import SwiftUI
import SwiftData
import MnemoCore
import MnemoMemory
import MnemoIntelligence
import MnemoSecurity

/// Top-level application state observable by all views.
@Observable
final class AppState {

    var isInitialised: Bool = false
    var deviceCapability: DeviceCapability = CapabilityDetector().detect()
    var onboardingComplete: Bool = false
    var appLockEnabled: Bool = false
    var isAppLocked: Bool = false
    var isAuthenticatingAppLock: Bool = false
    var appLockErrorMessage: String?

    private let appLockPolicy = AppLockPolicy(backgroundGracePeriod: 0)
    private var backgroundedAt: Date?

    func initialise() async {
        // Load Foundation Models availability
        await FoundationModelLoader.shared.load()

        // Open the vector store early so semantic search is ready for capture/recall.
        try? await VectorBridge.shared.open()

        let settings = await MainActor.run {
            let context = MemoryStore.shared.container.mainContext
            let descriptor = FetchDescriptor<UserModel>()
            let userModel = (try? context.fetch(descriptor))?.first
            return (
                onboardingComplete: userModel?.onboardingComplete ?? false,
                appLockEnabled: userModel?.appLockEnabled ?? false
            )
        }

        await MainActor.run {
            onboardingComplete = settings.onboardingComplete
            appLockEnabled = settings.appLockEnabled && SecurityLayer.shared.canAuthenticateWithBiometrics()
            isAppLocked = appLockPolicy.shouldLockOnLaunch(
                appLockEnabled: appLockEnabled,
                onboardingComplete: onboardingComplete
            )
            isInitialised = true
        }
    }

    @MainActor
    func handleScenePhase(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .background:
            backgroundedAt = Date()
            lockIfNeeded()
        case .active:
            break
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    @MainActor
    func unlockApp() async {
        guard appLockEnabled, onboardingComplete else {
            isAppLocked = false
            return
        }
        guard !isAuthenticatingAppLock else { return }

        isAuthenticatingAppLock = true
        appLockErrorMessage = nil

        do {
            let success = try await SecurityLayer.shared.authenticateWithBiometrics(
                reason: "Unlock Mnemo to view your saved memories."
            )
            if success {
                isAppLocked = false
                backgroundedAt = nil
            } else {
                appLockErrorMessage = "Mnemo is still locked. Try again when you are ready."
            }
        } catch {
            appLockErrorMessage = "Mnemo is still locked. Use Face ID, Touch ID or your device passcode to unlock."
        }

        isAuthenticatingAppLock = false
    }

    @MainActor
    func setAppLockEnabled(_ enabled: Bool) {
        appLockEnabled = enabled
        if !enabled {
            isAppLocked = false
            appLockErrorMessage = nil
            backgroundedAt = nil
        }
    }

    @MainActor
    func resetAfterDeleteAllData() {
        onboardingComplete = false
        appLockEnabled = false
        isAppLocked = false
        isAuthenticatingAppLock = false
        appLockErrorMessage = nil
        backgroundedAt = nil
    }

    @MainActor
    private func lockIfNeeded(now: Date = Date()) {
        guard SecurityLayer.shared.canAuthenticateWithBiometrics() else {
            isAppLocked = false
            return
        }

        guard appLockPolicy.shouldLockAfterBackground(
            appLockEnabled: appLockEnabled,
            onboardingComplete: onboardingComplete,
            backgroundedAt: backgroundedAt,
            now: now
        ) else { return }

        isAppLocked = true
        appLockErrorMessage = nil
    }
}
