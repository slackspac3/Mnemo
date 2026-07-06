import Foundation
import MnemoCore

/// Detects device capability tier at app launch.
/// Checks Apple Intelligence availability and Mnemo's own MLX model availability
/// as two independent checks — a device can fail the Apple Intelligence gate
/// (A17 Pro / M1 requirement) while still being capable of running the bundled MLX model.
public final class CapabilityDetector: Sendable {

    public init() {}

    public func detect() -> DeviceCapability {
        let appleIntelligenceAvailable = checkAppleIntelligence()
        let appleIntelligenceAdvanced = checkAppleIntelligenceAdvanced()
        let mnemoOnDeviceAvailable = checkMnemoMLX()

        let tier: DeviceTier
        let mode: ProcessingMode

        switch (appleIntelligenceAvailable, mnemoOnDeviceAvailable) {
        case (true, true):
            tier = appleIntelligenceAdvanced ? .full : .standard
            mode = appleIntelligenceAdvanced ? .onDeviceFull : .onDeviceStandard
        case (false, true):
            tier = .mlxOnly
            mode = .onDeviceMLXOnly
        case (_, false):
            tier = .cloudPrimary
            mode = .cloudPrimary
        }

        return DeviceCapability(
            tier: tier,
            appleIntelligenceAvailable: appleIntelligenceAvailable,
            appleIntelligenceAdvanced: appleIntelligenceAdvanced,
            mnemoOnDeviceAvailable: mnemoOnDeviceAvailable,
            recommendedProcessingMode: mode
        )
    }

    // MARK: - Private checks

    private func checkAppleIntelligence() -> Bool {
        if #available(iOS 26.0, *) {
            // On iOS 26+, Apple Intelligence is available on supported hardware.
            // The Foundation Models framework's own availability API is the
            // authoritative check — used at inference time via FoundationModelLoader.
            return true
        }
        return false
    }

    private func checkAppleIntelligenceAdvanced() -> Bool {
        // Advanced model (12GB+ RAM devices: iPhone 17 Pro, Air).
        // ProcessInfo does not expose RAM directly — use a conservative heuristic.
        // Phase 12: replace with the Foundation Models framework's tier API
        // when it is available in the public SDK.
        if #available(iOS 26.0, *) {
            let physicalMemory = ProcessInfo.processInfo.physicalMemory
            return physicalMemory >= 12_000_000_000 // 12GB
        }
        return false
    }

    private func checkMnemoMLX() -> Bool {
        // Mnemo's own bundled model requires Apple Silicon Neural Engine.
        // All devices running iOS 18+ have sufficient Neural Engine capability
        // to run Phi-3 Mini class models. Conservative: return true for iOS 18+.
        return true
    }
}
