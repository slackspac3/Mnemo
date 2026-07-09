import Foundation
import MnemoCore

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Wraps Apple's Foundation Models framework for on-device LLM inference.
/// Uses availability checks so the app degrades gracefully on unsupported devices.
/// The actual FoundationModels import is gated — if the framework is unavailable
/// on the build machine, the loader falls back to unavailable state.
public actor FoundationModelLoader {

    public static let shared = FoundationModelLoader()

    public enum State: Sendable {
        case notLoaded
        case available
        case unavailable(String)
    }

    private(set) public var state: State = .notLoaded

    public init() {}

    public func load() async {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            state = .unavailable("Foundation Models require iOS 26.0, macOS 26.0, or visionOS 26.0.")
            return
        }

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            state = .unavailable(
                "Foundation Models unavailable: \(Self.availabilityDescription(model.availability))."
            )
            return
        }

        state = .available
        #else
        state = .unavailable("FoundationModels framework is unavailable in this build.")
        #endif
    }

    public var isAvailable: Bool {
        if case .available = state { return true }
        return false
    }

    /// Generate a completion using Foundation Models.
    /// Returns nil if unavailable — caller falls through to MLX or cloud.
    public func generate(prompt: String, maxTokens: Int = 512) async throws -> String? {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            state = .unavailable("Foundation Models require iOS 26.0, macOS 26.0, or visionOS 26.0.")
            return nil
        }

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            state = .unavailable(
                "Foundation Models unavailable: \(Self.availabilityDescription(model.availability))."
            )
            return nil
        }

        state = .available
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(
            to: prompt,
            options: GenerationOptions(
                sampling: .greedy,
                temperature: 0.0,
                maximumResponseTokens: maxTokens
            )
        )
        return response.content
        #else
        state = .unavailable("FoundationModels framework is unavailable in this build.")
        return nil
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private static func availabilityDescription(
        _ availability: SystemLanguageModel.Availability
    ) -> String {
        switch availability {
        case .available:
            return "available"
        case .unavailable(.deviceNotEligible):
            return "deviceNotEligible"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "appleIntelligenceNotEnabled"
        case .unavailable(.modelNotReady):
            return "modelNotReady"
        @unknown default:
            return "unknown"
        }
    }
    #endif
}
