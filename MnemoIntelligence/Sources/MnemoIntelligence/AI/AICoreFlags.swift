import Foundation

/// Feature flags for the AI Core prototype.
///
/// The default keeps every model-backed path disabled so the current
/// TestFlight-safe V1 recall loop remains deterministic unless an internal
/// build explicitly opts in.
public struct AICoreFlags: Equatable, Sendable {
    public var aiCoreEnabled: Bool
    public var mlxEmbeddingsEnabled: Bool
    public var mlxAnswerComposerEnabled: Bool
    public var foundationModelsEnabled: Bool
    public var deterministicRecallFallbackEnabled: Bool

    public init(
        aiCoreEnabled: Bool = false,
        mlxEmbeddingsEnabled: Bool = false,
        mlxAnswerComposerEnabled: Bool = false,
        foundationModelsEnabled: Bool = false,
        deterministicRecallFallbackEnabled: Bool = true
    ) {
        self.aiCoreEnabled = aiCoreEnabled
        self.mlxEmbeddingsEnabled = mlxEmbeddingsEnabled
        self.mlxAnswerComposerEnabled = mlxAnswerComposerEnabled
        self.foundationModelsEnabled = foundationModelsEnabled
        self.deterministicRecallFallbackEnabled = deterministicRecallFallbackEnabled
    }

    public static let testFlightDefault = AICoreFlags()

    public static let debugPrototype = AICoreFlags(
        aiCoreEnabled: true,
        mlxEmbeddingsEnabled: true,
        mlxAnswerComposerEnabled: false,
        foundationModelsEnabled: false,
        deterministicRecallFallbackEnabled: true
    )

    public var hasModelBackedPathEnabled: Bool {
        aiCoreEnabled &&
            (mlxEmbeddingsEnabled || mlxAnswerComposerEnabled || foundationModelsEnabled)
    }
}
