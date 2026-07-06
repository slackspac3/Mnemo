import Foundation

public enum CorroborationType: Sendable {
    case noMatch
    case confirms
    case contradicts
}

public struct CorroborationResult: Sendable {
    public let existingMemoryId: UUID?
    public let corroborationType: CorroborationType
    public let persistenceDelta: Double

    public init(
        existingMemoryId: UUID? = nil,
        corroborationType: CorroborationType,
        persistenceDelta: Double = 0.0
    ) {
        self.existingMemoryId = existingMemoryId
        self.corroborationType = corroborationType
        self.persistenceDelta = persistenceDelta
    }
}
