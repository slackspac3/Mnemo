import Foundation

public struct ThreadProposal: Sendable, Identifiable {
    public let id: UUID
    public let suggestedName: String
    public let suggestedDescription: String
    public let memoryIds: [UUID]
    public let dateRange: ClosedRange<Date>
    public let confidence: Double

    public init(
        id: UUID = UUID(),
        suggestedName: String,
        suggestedDescription: String,
        memoryIds: [UUID],
        dateRange: ClosedRange<Date>,
        confidence: Double
    ) {
        self.id = id
        self.suggestedName = suggestedName
        self.suggestedDescription = suggestedDescription
        self.memoryIds = memoryIds
        self.dateRange = dateRange
        self.confidence = confidence
    }
}
