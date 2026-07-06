import Foundation
import SwiftData

/// A confirmed or proposed narrative cluster of related memories.
/// Memories belong to a thread via MemoryRecord.threadId — not a direct relationship,
/// to avoid cascade side effects when threads are dissolved.
@Model
public final class MemoryThread {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var threadDescription: String
    public var startDate: Date
    public var endDate: Date?
    public var isConfirmed: Bool
    public var proposalConfidence: Double
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        threadDescription: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        isConfirmed: Bool = false,
        proposalConfidence: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.threadDescription = threadDescription
        self.startDate = startDate
        self.endDate = endDate
        self.isConfirmed = isConfirmed
        self.proposalConfidence = proposalConfidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
