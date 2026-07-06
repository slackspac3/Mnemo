import Foundation
import SwiftData
import MnemoCore

/// Audit log entry for every memory conflict resolution.
@Model
public final class ConflictRecord {
    @Attribute(.unique) public var id: UUID
    public var incomingMemoryId: UUID
    public var existingMemoryId: UUID
    public var resolution: String            // ConflictResolution case name
    public var resolvedAt: Date

    public init(
        id: UUID = UUID(),
        incomingMemoryId: UUID,
        existingMemoryId: UUID,
        resolution: String,
        resolvedAt: Date = Date()
    ) {
        self.id = id
        self.incomingMemoryId = incomingMemoryId
        self.existingMemoryId = existingMemoryId
        self.resolution = resolution
        self.resolvedAt = resolvedAt
    }
}
