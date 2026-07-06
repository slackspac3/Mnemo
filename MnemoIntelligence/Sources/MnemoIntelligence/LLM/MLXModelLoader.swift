import Foundation
import MnemoCore

/// Loads and manages the bundled MLX model (Phi-3 Mini 4K Instruct).
/// Used as fallback when Apple Foundation Models is unavailable (Tier 3 devices)
/// or as the primary extractor for custom model tasks.
/// Implemented as a singleton actor for thread safety and to prevent
/// multiple simultaneous model loads consuming device memory.
public actor MLXModelLoader {

    public static let shared = MLXModelLoader()

    public enum State: Sendable {
        case notLoaded
        case loading
        case ready
        case failed(String)
    }

    private(set) public var state: State = .notLoaded

    public init() {}

    /// Load the MLX model from the app bundle.
    /// In production this loads Phi-3 Mini 4K Instruct in MLX format
    /// delivered via On-Demand Resources. In Phase 4 this is a stub
    /// that marks the loader as ready for testing purposes.
    public func load() async throws {
        guard case .notLoaded = state else { return }
        state = .loading
        // Phase 4 stub: mark ready immediately.
        // Phase 12: replace with actual MLX model loading via MLXSwift.
        state = .ready
    }

    public func unload() {
        state = .notLoaded
    }

    public var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    /// Run inference with the loaded MLX model.
    /// Returns nil if not ready — caller falls through to cloud.
    public func generate(prompt: String, maxTokens: Int = 512) async throws -> String? {
        guard isReady else { return nil }
        // Phase 4 stub: return nil so tests can exercise the cloud fallback path.
        // Phase 12: replace with actual MLXSwift inference call.
        return nil
    }
}
