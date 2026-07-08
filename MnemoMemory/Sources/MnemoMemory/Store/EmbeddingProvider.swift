import Foundation

/// Describes how an embedding was produced.
///
/// The current TestFlight-safe provider is deterministic and local. Future MLX
/// providers must expose their model identity and dimensionality here before
/// their vectors are written to the local index.
public struct EmbeddingProviderDescriptor: Equatable, Sendable {
    public let id: String
    public let version: String
    public let dimensions: Int
    public let executionScope: EmbeddingExecutionScope

    public init(
        id: String,
        version: String,
        dimensions: Int,
        executionScope: EmbeddingExecutionScope
    ) {
        self.id = id
        self.version = version
        self.dimensions = dimensions
        self.executionScope = executionScope
    }
}

public enum EmbeddingExecutionScope: String, Equatable, Sendable {
    case deterministicLocal
    case mlxLocal
}

public enum EmbeddingProviderError: Error, Equatable, Sendable {
    case unavailable(String)
    case dimensionMismatch(expected: Int, actual: Int)
}

public protocol EmbeddingProvider: Sendable {
    var descriptor: EmbeddingProviderDescriptor { get }
    func embed(_ text: String) throws -> [Float]
}

/// Current deterministic V1 embedding provider.
public struct CharacterFrequencyEmbeddingProvider: EmbeddingProvider {
    public static let dimensions = 26

    public let descriptor = EmbeddingProviderDescriptor(
        id: "mnemo.character-frequency",
        version: "1",
        dimensions: dimensions,
        executionScope: .deterministicLocal
    )

    public init() {}

    public func embed(_ text: String) throws -> [Float] {
        var frequency = [Float](repeating: 0, count: Self.dimensions)
        let lowercased = text.lowercased()

        for character in lowercased {
            if let ascii = character.asciiValue {
                let index = Int(ascii) - Int(Character("a").asciiValue!)
                if index >= 0, index < Self.dimensions {
                    frequency[index] += 1
                }
            }
        }

        let magnitude = sqrt(frequency.map { $0 * $0 }.reduce(0, +))
        guard magnitude > 0 else { return frequency }
        return frequency.map { $0 / magnitude }
    }
}

/// Spike boundary for a future MLX Swift embedding provider.
///
/// This type intentionally does not import MLX or claim model availability. It
/// gives the app a concrete provider boundary while failing closed until a real
/// model package, assets, and Xcode/device validation are added on this branch.
public struct MLXEmbeddingProvider: EmbeddingProvider {
    public let descriptor: EmbeddingProviderDescriptor
    private let modelDirectory: URL?

    public init(
        modelDirectory: URL? = nil,
        modelID: String = "mnemo.mlx.embedding.unconfigured",
        modelVersion: String = "0",
        dimensions: Int = 0
    ) {
        self.modelDirectory = modelDirectory
        self.descriptor = EmbeddingProviderDescriptor(
            id: modelID,
            version: modelVersion,
            dimensions: dimensions,
            executionScope: .mlxLocal
        )
    }

    public func embed(_ text: String) throws -> [Float] {
        guard let modelDirectory else {
            throw EmbeddingProviderError.unavailable("MLX embedding model assets are not configured")
        }
        guard FileManager.default.fileExists(atPath: modelDirectory.path) else {
            throw EmbeddingProviderError.unavailable("MLX embedding model assets are not present")
        }

        throw EmbeddingProviderError.unavailable("MLX embedding runtime is not linked in this build")
    }
}
