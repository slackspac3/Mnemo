import Foundation
import SwiftUI
import MnemoCore
import MnemoMemory
import MnemoIntelligence

/// Top-level application state observable by all views.
@Observable
final class AppState {

    var isInitialised: Bool = false
    var deviceCapability: DeviceCapability = CapabilityDetector().detect()
    var onboardingComplete: Bool = false

    func initialise() async {
        // Load Foundation Models availability
        await FoundationModelLoader.shared.load()

        // Open the vector store early so semantic search is ready for capture/recall.
        try? await VectorBridge.shared.open()

        // Check onboarding status (read from UserModel when available)
        // Phase 7: default to false until onboarding is built in Phase 11
        onboardingComplete = false
        isInitialised = true
    }
}
