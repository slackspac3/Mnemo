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

        await applyUITestingLaunchArgumentsIfNeeded()

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

    @MainActor
    private func applyUITestingLaunchArgumentsIfNeeded() async {
        #if DEBUG
        guard UITestingLaunchArguments.isUITesting else { return }

        let context = MemoryStore.shared.container.mainContext

        if UITestingLaunchArguments.resetDataOnLaunch {
            try? await VectorBridge.shared.wipe()
            try? context.delete(model: MemoryRecord.self)
            try? context.delete(model: MemoryThread.self)
            try? context.delete(model: UserModel.self)
            try? context.delete(model: ConflictRecord.self)
            try? context.delete(model: PersonSubject.self)
            try? context.save()
            NavigationCoordinator.shared.dismiss()
        }

        if UITestingLaunchArguments.skipOnboardingIfNeeded {
            let descriptor = FetchDescriptor<UserModel>()
            let userModel = (try? context.fetch(descriptor))?.first

            if let userModel {
                userModel.onboardingComplete = true
                userModel.appLockEnabled = false
                userModel.updatedAt = Date()
            } else {
                context.insert(UserModel(onboardingComplete: true, appLockEnabled: false))
            }

            try? context.save()
        }
        #endif
    }
}

#if DEBUG
private enum UITestingLaunchArguments {
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
    static let resetDataOnLaunch = ProcessInfo.processInfo.arguments.contains("--reset-data-on-launch")
    static let skipOnboardingIfNeeded = ProcessInfo.processInfo.arguments.contains("--skip-onboarding-if-needed")
}
#endif
