import Foundation
import SwiftData

/// A person in the user's life that memories can be tagged to.
/// Enables the Mnemo Sense People layer.
/// Only created when the user explicitly tags a memory to a person —
/// never inferred silently from incidental name mentions.
@Model
public final class PersonSubject {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var relationship: String?         // User-defined free text e.g. 'colleague', 'friend'
    public var lastMentioned: Date
    public var memoryIds: [UUID]             // All MemoryRecord IDs tagged to this person

    public init(
        id: UUID = UUID(),
        name: String,
        relationship: String? = nil,
        lastMentioned: Date = Date(),
        memoryIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.lastMentioned = lastMentioned
        self.memoryIds = memoryIds
    }
}
