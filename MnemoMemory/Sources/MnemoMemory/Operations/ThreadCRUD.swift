import Foundation
import SwiftData
import MnemoCore

/// CRUD operations for MemoryThread.
public struct ThreadCRUD {

    public static func insert(_ thread: MemoryThread, into context: ModelContext) throws {
        context.insert(thread)
        try context.save()
    }

    public static func fetchAll(
        confirmedOnly: Bool = false,
        in context: ModelContext
    ) throws -> [MemoryThread] {
        let descriptor = FetchDescriptor<MemoryThread>(
            predicate: confirmedOnly ? #Predicate { $0.isConfirmed } : nil,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public static func fetch(id: UUID, in context: ModelContext) throws -> MemoryThread? {
        let descriptor = FetchDescriptor<MemoryThread>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    public static func confirm(
        id: UUID,
        name: String,
        description: String,
        startDate: Date,
        endDate: Date?,
        in context: ModelContext
    ) throws {
        guard let thread = try fetch(id: id, in: context) else { return }
        thread.name = name
        thread.threadDescription = description
        thread.startDate = startDate
        thread.endDate = endDate
        thread.isConfirmed = true
        thread.updatedAt = Date()
        try context.save()
    }

    public static func dissolve(id: UUID, in context: ModelContext) throws {
        guard let thread = try fetch(id: id, in: context) else { return }
        // Clear threadId from all member memories
        let memoryDescriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.threadId == id }
        )
        let members = try context.fetch(memoryDescriptor)
        for memory in members {
            memory.threadId = nil
            memory.updatedAt = Date()
        }
        context.delete(thread)
        try context.save()
    }
}
