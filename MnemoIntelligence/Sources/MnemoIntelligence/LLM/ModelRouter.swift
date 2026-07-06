import Foundation
import MnemoCore
import MnemoMemory

/// Routes extraction and recall requests to the appropriate model tier.
/// Consults DeviceCapability before deciding whether on-device is attempted.
/// Holds a reference to the cloud provider (configured when provider is chosen).
/// Phase 4: shell implementation — cloud provider is nil, on-device stubs used.
/// Phase 6: cloud provider wired in, full routing logic active.
public final class ModelRouter: ModelRouterProtocol, @unchecked Sendable {

    public var preferOnDevice: Bool
    private let capability: DeviceCapability
    private let extractionEngine: ExtractionEngine

    public init(
        capability: DeviceCapability,
        preferOnDevice: Bool = true,
        extractionEngine: ExtractionEngine = ExtractionEngine()
    ) {
        self.capability = capability
        self.preferOnDevice = preferOnDevice
        self.extractionEngine = extractionEngine
    }

    public func extract(
        rawInput: String,
        source: InputSource,
        userContext: String?,
        threshold: Double
    ) async throws -> ExtractionResult {
        let cloudPermitted = !preferOnDevice &&
            capability.recommendedProcessingMode != .cloudPrimary
        return try await extractionEngine.extract(
            rawText: rawInput,
            source: source,
            userContext: userContext,
            threshold: threshold,
            cloudPermitted: cloudPermitted
        )
    }

    public func answer(
        query: String,
        memories: [MemorySnapshot]
    ) async throws -> String {
        // Phase 4 stub — full implementation in Phase 6
        return "I have \(memories.count) memories that may be relevant."
    }

    public func detectThreads(
        memories: [MemorySnapshot]
    ) async throws -> [ThreadProposal] {
        // Phase 4 stub — full implementation in Phase 7
        return []
    }
}
