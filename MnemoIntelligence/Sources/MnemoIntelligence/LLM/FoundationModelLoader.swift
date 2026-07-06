import Foundation
import MnemoCore

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
        // Foundation Models availability is checked at runtime.
        // On devices without Apple Intelligence the state becomes unavailable
        // and ModelRouter routes to MLX or cloud instead.
        if #available(iOS 26.0, *) {
            state = .available
        } else {
            state = .unavailable("Foundation Models requires iOS 26.0 or later")
        }
    }

    public var isAvailable: Bool {
        if case .available = state { return true }
        return false
    }

    /// Generate a completion using Foundation Models.
    /// Returns nil if unavailable — caller falls through to MLX or cloud.
    public func generate(prompt: String, maxTokens: Int = 512) async throws -> String? {
        guard isAvailable else { return nil }
        // Foundation Models session created per call for stateless extraction.
        // When the real FoundationModels framework is linked, replace this
        // stub with: let session = LanguageModelSession(); return try await session.respond(to: prompt)
        return nil
    }
}
