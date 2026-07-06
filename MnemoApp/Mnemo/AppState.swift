import Foundation
import SwiftUI
import SwiftData
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

        let completed = await MainActor.run {
            let context = MemoryStore.shared.container.mainContext
            let descriptor = FetchDescriptor<UserModel>()
            return ((try? context.fetch(descriptor))?.first?.onboardingComplete) ?? false
        }

        await MainActor.run {
            onboardingComplete = completed
            isInitialised = true
        }
    }
}
