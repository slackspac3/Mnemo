import Foundation
import MnemoCore

/// Placeholder for a future bundled MLX model route.
/// This build does not ship production MLX inference; callers should expect nil
/// generation until real model loading is wired.
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

    /// Load the future MLX model from the app bundle.
    /// In this build no MLX model assets are bundled, so the loader remains unavailable.
    public func load() async throws {
        guard case .notLoaded = state else { return }
        state = .loading
        // Replace with actual MLXSwift model loading only after the dependency,
        // model assets, memory budget, and app build path are validated.
        state = .failed("MLX model assets are not bundled in this build")
    }

    public func unload() {
        state = .notLoaded
    }

    public var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    /// Run inference with the loaded MLX model.
    /// Returns nil in this build because production MLX inference is not wired.
    public func generate(prompt: String, maxTokens: Int = 512) async throws -> String? {
        guard isReady else { return nil }
        // Phase 4 stub: return nil so tests can exercise the cloud fallback path.
        // Phase 12: replace with actual MLXSwift inference call.
        return nil
    }
}
