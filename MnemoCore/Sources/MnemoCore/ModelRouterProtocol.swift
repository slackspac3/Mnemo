import Foundation

public protocol ModelRouterProtocol: Sendable {
    func extract(
        rawInput: String,
        source: InputSource,
        userContext: String?,
        threshold: Double
    ) async throws -> ExtractionResult

    func answer(
        query: String,
        memories: [MemorySnapshot]
    ) async throws -> String

    func detectThreads(
        memories: [MemorySnapshot]
    ) async throws -> [ThreadProposal]

    var preferOnDevice: Bool { get set }
}
