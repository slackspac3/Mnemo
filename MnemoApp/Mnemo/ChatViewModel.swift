import Foundation
import SwiftData
import SwiftUI
import MnemoCore
import MnemoMemory

/// ViewModel for ChatView.
/// Manages the conversation history, memory recall, and pattern insights.
@Observable
final class ChatViewModel {

    struct Message: Identifiable {
        let id: UUID
        let role: Role
        let content: String
        let timestamp: Date
        let citedMemoryIds: [UUID]
        let citations: [Citation]

        enum Role {
            case user
            case assistant
        }

        struct Citation: Identifiable, Hashable {
            let id: UUID
            let summary: String
            let source: String
        }

        init(
            id: UUID = UUID(),
            role: Role,
            content: String,
            timestamp: Date = Date(),
            citedMemoryIds: [UUID] = [],
            citations: [Citation] = []
        ) {
            self.id = id
            self.role = role
            self.content = content
            self.timestamp = timestamp
            self.citedMemoryIds = citedMemoryIds
            self.citations = citations
        }
    }

    var messages: [Message] = []
    var inputText = ""
    var isProcessing = false
    var errorMessage: String?

    func resetConversation() {
        messages = []
        inputText = ""
        errorMessage = nil
    }

    @MainActor
    func send(context: ModelContext) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isProcessing else { return }

        inputText = ""
        isProcessing = true
        errorMessage = nil

        messages.append(Message(role: .user, content: text))

        do {
            let response: RecallResponse
            if let updateResponse = try await updateReferencedMemoryIfNeeded(
                query: text,
                context: context
            ) {
                response = updateResponse
            } else {
                response = try await recall(query: text, context: context)
            }
            messages.append(Message(
                role: .assistant,
                content: response.text,
                citedMemoryIds: response.citedMemoryIds,
                citations: response.citations
            ))
        } catch {
            errorMessage = "Something went wrong. Try again."
            messages.append(Message(
                role: .assistant,
                content: "I had trouble finding that. Try asking differently."
            ))
        }

        isProcessing = false
    }

    @MainActor
    private func updateReferencedMemoryIfNeeded(
        query: String,
        context: ModelContext
    ) async throws -> RecallResponse? {
        guard isMemoryUpdateRequest(query) else { return nil }

        let citedIds = lastCitedMemoryIds()
        guard !citedIds.isEmpty else { return nil }

        let citedMemories = try citedIds.compactMap { id in
            try MemoryCRUD.fetch(id: id, in: context)
        }
        guard !citedMemories.isEmpty else { return nil }

        if let requestedSize = requestedSizeUpdate(from: query) {
            return try await updateSizeMemories(
                citedMemories,
                requestedSize: requestedSize,
                context: context
            )
        }

        guard let correction = genericCorrection(from: query) else {
            return RecallResponse(
                text: "I can update that memory, but I need the correction in a clearer form. Try: \"Update it to ...\" or \"Change ... to ...\".",
                citedMemoryIds: citedIds,
                citations: citations(for: citedMemories)
            )
        }

        return try await updateGenericMemories(
            citedMemories,
            correction: correction,
            context: context
        )
    }

    @MainActor
    private func updateSizeMemories(
        _ citedMemories: [MemoryRecord],
        requestedSize: String,
        context: ModelContext
    ) async throws -> RecallResponse? {
        guard let sizeMemory = citedMemories.first(where: { memory in
            extractSizeFact(from: searchableText(for: memory), memory: memory) != nil
        }) else {
            return RecallResponse(
                text: "I found the memory you were referring to, but I could not find a size in it to update.",
                citedMemoryIds: citedMemories.map(\.id),
                citations: citations(for: citedMemories)
            )
        }
        let sizeMemories = [sizeMemory]

        let normalisedSize = normaliseSize(requestedSize)
        let displaySize = displaySize(for: normalisedSize)
        let now = Date()

        for memory in sizeMemories {
            memory.summary = replacingSize(in: memory.summary, with: displaySize)
            memory.rawInput = replacingSize(in: memory.rawInput, with: displaySize)
            memory.updatedAt = now
        }
        try context.save()
        await reindex(memories: sizeMemories)

        let firstMemory = sizeMemories[0]
        let memoryText = searchableText(for: firstMemory)
        let location = extractLocation(from: memoryText)
        let item = itemLabel(for: memoryText)
        let subject = sizeSubject(item: item, location: location, query: "", memoryText: memoryText)
        let sentenceSubject = updateConfirmationSubject(subject: subject, memoryText: memoryText)

        return RecallResponse(
            text: "Updated. \(sentenceSubject) is now \(displaySize).",
            citedMemoryIds: sizeMemories.map(\.id),
            citations: citations(for: sizeMemories)
        )
    }

    @MainActor
    private func updateGenericMemories(
        _ citedMemories: [MemoryRecord],
        correction: MemoryCorrection,
        context: ModelContext
    ) async throws -> RecallResponse {
        let memoriesToUpdate: [MemoryRecord]
        switch correction {
        case .replace(let oldValue, _):
            memoriesToUpdate = citedMemories.filter { memory in
                searchableText(for: memory).range(of: oldValue, options: .caseInsensitive) != nil
            }
        case .rewrite:
            memoriesToUpdate = Array(citedMemories.prefix(1))
        }

        guard !memoriesToUpdate.isEmpty else {
            return RecallResponse(
                text: "I found the memory you were referring to, but I could not find the text you wanted changed.",
                citedMemoryIds: citedMemories.map(\.id),
                citations: citations(for: citedMemories)
            )
        }

        let now = Date()
        for memory in memoriesToUpdate {
            switch correction {
            case .replace(let oldValue, let newValue):
                memory.summary = replacingText(
                    in: memory.summary,
                    oldValue: oldValue,
                    newValue: newValue
                )
                memory.rawInput = replacingText(
                    in: memory.rawInput,
                    oldValue: oldValue,
                    newValue: newValue
                )
            case .rewrite(let newValue):
                memory.summary = newValue
                memory.rawInput = newValue
            }
            memory.updatedAt = now
        }

        try context.save()
        await reindex(memories: memoriesToUpdate)

        let updatedSummary = summaryLine(for: memoriesToUpdate[0])
        return RecallResponse(
            text: "Updated that memory to: \"\(updatedSummary)\"",
            citedMemoryIds: memoriesToUpdate.map(\.id),
            citations: citations(for: memoriesToUpdate)
        )
    }

    @MainActor
    private func recall(query: String, context: ModelContext) async throws -> RecallResponse {
        let memories = try MemoryCRUD.fetchAll(in: context)
        let result = RecallEngine().recall(query: query, memories: memories)
        return RecallResponse(
            text: result.text,
            citedMemoryIds: result.citedMemoryIds,
            citations: result.citations.map { citation in
                Message.Citation(
                    id: citation.id,
                    summary: citation.summary,
                    source: citation.source
                )
            }
        )
    }

    private func summaryLine(for memory: MemoryRecord) -> String {
        let summary = memory.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty { return summary }

        let rawInput = memory.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !rawInput.isEmpty { return rawInput }

        return "Untitled memory"
    }

    private func searchableText(for memory: MemoryRecord) -> String {
        ([memory.summary, memory.rawInput] + memory.tags).joined(separator: " ")
    }

    private func isMemoryUpdateRequest(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("update") ||
            lowercased.contains("change") ||
            lowercased.contains("correct") ||
            lowercased.contains("replace") ||
            lowercased.contains("actually") ||
            lowercased.contains("no longer")
    }

    private func requestedSizeUpdate(from query: String) -> String? {
        let lowercased = query.lowercased()
        guard lowercased.contains("update") ||
            lowercased.contains("change") ||
            lowercased.contains("set") ||
            lowercased.contains("make")
        else { return nil }

        let patterns = [
            #"\b(?:update|change|set|make)\b.*\b(?:to|as)\s+(?:size\s+)?(xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b"#,
            #"\bnow\s+(?:it\s+)?(?:is|=)\s*(xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            ) else { continue }

            let range = NSRange(query.startIndex..<query.endIndex, in: query)
            guard let match = regex.firstMatch(in: query, range: range),
                  match.numberOfRanges > 1,
                  let sizeRange = Range(match.range(at: 1), in: query)
            else { continue }

            return String(query[sizeRange])
        }

        return nil
    }

    private func genericCorrection(from query: String) -> MemoryCorrection? {
        if let replacement = replacementCorrection(from: query) {
            return replacement
        }

        if let rewrite = rewriteCorrection(from: query) {
            return .rewrite(rewrite)
        }

        return nil
    }

    private func replacementCorrection(from query: String) -> MemoryCorrection? {
        let patterns = [
            #"\b(?:change|correct|replace)\s+(.+?)\s+(?:to|with)\s+(.+)"#,
            #"\b(.+?)\s+(?:is|are|was|were)\s+no\s+longer\s+(.+)"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            ) else { continue }

            let range = NSRange(query.startIndex..<query.endIndex, in: query)
            guard let match = regex.firstMatch(in: query, range: range),
                  match.numberOfRanges > 2,
                  let firstRange = Range(match.range(at: 1), in: query),
                  let secondRange = Range(match.range(at: 2), in: query)
            else { continue }

            let first = cleanCorrectionPhrase(String(query[firstRange]))
            let second = cleanCorrectionPhrase(String(query[secondRange]))
            guard !first.isEmpty, !second.isEmpty else { continue }

            if pattern.contains("no\\s+longer") {
                return .replace(oldValue: second, newValue: first)
            }
            return .replace(oldValue: first, newValue: second)
        }

        return nil
    }

    private func rewriteCorrection(from query: String) -> String? {
        let patterns = [
            #"\b(?:update|set|make)\s+(?:it|that|this|the memory)\s+(?:to|as)\s+(.+)"#,
            #"\b(?:actually|correction[:,]?)\s+(.+)"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            ) else { continue }

            let range = NSRange(query.startIndex..<query.endIndex, in: query)
            guard let match = regex.firstMatch(in: query, range: range),
                  match.numberOfRanges > 1,
                  let valueRange = Range(match.range(at: 1), in: query)
            else { continue }

            let value = cleanCorrectionPhrase(String(query[valueRange]))
            if !value.isEmpty {
                return value
            }
        }

        return nil
    }

    private func cleanCorrectionPhrase(_ phrase: String) -> String {
        phrase
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private func lastCitedMemoryIds() -> [UUID] {
        guard messages.last?.role == .user else { return [] }
        guard let previousAssistant = messages.dropLast().reversed().first(where: { message in
            message.role == .assistant
        }) else { return [] }
        return Array(previousAssistant.citedMemoryIds.prefix(1))
    }

    private func replacingSize(in text: String, with displaySize: String) -> String {
        let pattern = #"\b(?:xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else { return text }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: displaySize
        )
    }

    private func replacingText(
        in text: String,
        oldValue: String,
        newValue: String
    ) -> String {
        text.replacingOccurrences(
            of: oldValue,
            with: newValue,
            options: [.caseInsensitive]
        )
    }

    private func reindex(memories: [MemoryRecord]) async {
        for memory in memories {
            try? await EmbeddingHelper.shared.index(
                id: memory.id,
                summary: memory.summary
            )
        }
    }

    private func citations(for memories: [MemoryRecord]) -> [Message.Citation] {
        memories.map { memory in
            Message.Citation(
                id: memory.id,
                summary: summaryLine(for: memory),
                source: memory.inputSource.capitalized
            )
        }
    }

    private func sizeSubject(item: String, location: String?) -> String {
        sizeSubject(item: item, location: location, query: "", memoryText: "")
    }

    private func sizeSubject(
        item: String,
        location: String?,
        query: String,
        memoryText: String
    ) -> String {
        let combinedText = "\(query) \(memoryText)".lowercased()
        if combinedText.contains("mum") ||
            combinedText.contains("mom") ||
            combinedText.contains("mother") {
            if combinedText.contains("shoe") {
                return "Mum's shoe size"
            }
            return "Mum's size"
        }

        if let owner = sizeOwner(from: memoryText) {
            if combinedText.contains("shoe") {
                return "\(owner)'s shoe size"
            }
            return "\(owner)'s size"
        }

        if let location, item == "size" {
            return "\(location) size"
        } else if let location {
            return "\(location) \(item) size"
        } else if item == "size" {
            return "size"
        } else {
            return "\(item) size"
        }
    }

    private func updateConfirmationSubject(subject: String, memoryText: String) -> String {
        if subject.contains("'s") {
            return subject
        }

        let lowercasedMemory = memoryText.lowercased()
        if lowercasedMemory.contains("my ") || lowercasedMemory.contains("remember that my ") {
            return "Your \(subject)"
        }

        if subject == "size" {
            return "That saved size"
        }

        return "That saved \(subject)"
    }

    private func sizeOwner(from text: String) -> String? {
        let patterns = [
            #"\b(mum|mom|mother|dad|father|[A-Z][a-z]+)\s+(?:wears|wear|has)\s+(?:a\s+)?(?:shoe\s+)?size\b"#,
            #"\b(mum|mom|mother|dad|father|[A-Z][a-z]+)'s\s+(?:shoe\s+)?size\b"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: []
            ) else { continue }

            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  match.numberOfRanges > 1,
                  let ownerRange = Range(match.range(at: 1), in: text)
            else { continue }

            let owner = String(text[ownerRange])
            switch owner.lowercased() {
            case "mom", "mother":
                return "Mum"
            case "dad", "father":
                return "Dad"
            default:
                return owner.prefix(1).uppercased() + String(owner.dropFirst())
            }
        }

        return nil
    }

    private func extractSizeFact(from text: String, memory: MemoryRecord) -> SizeFact? {
        let patterns: [(pattern: String, sizeGroup: Int, locationGroup: Int?)] = [
            (#"\b(?:size\s+)?(?:is|=|:)\s*(xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b"#, 1, nil),
            (#"\bsize\s+(xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b"#, 1, nil),
            (#"\b(xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b\s+(?:in|at|for)\s+([^.,;\n]+)"#, 1, 2),
        ]

        for entry in patterns {
            guard let regex = try? NSRegularExpression(
                pattern: entry.pattern,
                options: [.caseInsensitive]
            ) else { continue }

            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  let sizeRange = Range(match.range(at: entry.sizeGroup), in: text)
            else { continue }

            let rawSize = String(text[sizeRange])
            let normalisedSize = normaliseSize(rawSize)
            let displaySize = displaySize(for: normalisedSize)
            let location: String?
            if let locationGroup = entry.locationGroup,
               let locationRange = Range(match.range(at: locationGroup), in: text) {
                location = cleanLocationPhrase(String(text[locationRange]))
            } else {
                location = extractLocation(from: text)
            }

            return SizeFact(
                displaySize: displaySize,
                normalisedSize: normalisedSize,
                location: location,
                memory: memory
            )
        }

        return nil
    }

    private func itemLabel(for query: String) -> String {
        let lowercased = query.lowercased()
        if lowercased.contains("t-shirt") ||
            lowercased.contains("t shirt") ||
            lowercased.contains("shirt") {
            return "T-shirt"
        }
        return "size"
    }

    private func normaliseSize(_ size: String) -> String {
        switch size.lowercased() {
        case "small", "s":
            return "small"
        case "medium", "m":
            return "medium"
        case "large", "l":
            return "large"
        default:
            return size.lowercased()
        }
    }

    private func displaySize(for normalisedSize: String) -> String {
        switch normalisedSize {
        case "small":
            return "S"
        case "medium":
            return "M"
        case "large":
            return "L"
        default:
            return normalisedSize.uppercased()
        }
    }

    private func extractLocation(from text: String) -> String? {
        let patterns = [
            #"\b(?:in|at|near)\s+([^.,;\n]+)"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            ) else { continue }

            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  match.numberOfRanges > 1,
                  let matchRange = Range(match.range(at: 1), in: text)
            else { continue }

            let phrase = cleanLocationPhrase(String(text[matchRange]))
            if !phrase.isEmpty {
                return phrase
            }
        }

        return nil
    }

    private func cleanLocationPhrase(_ phrase: String) -> String {
        let stopMarkers = [" is ", " was ", " were ", " for ", " because ", " when ", " that "]
        let lowercased = phrase.lowercased()

        var endIndex = phrase.endIndex
        for marker in stopMarkers {
            if let range = lowercased.range(of: marker),
               range.lowerBound < endIndex {
                endIndex = range.lowerBound
            }
        }

        return String(phrase[..<endIndex])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'?.!"))
    }

    private struct RecallResponse {
        let text: String
        let citedMemoryIds: [UUID]
        let citations: [Message.Citation]

        init(
            text: String,
            citedMemoryIds: [UUID],
            citations: [Message.Citation] = []
        ) {
            self.text = text
            self.citedMemoryIds = citedMemoryIds
            self.citations = citations
        }
    }

    private struct SizeFact {
        let displaySize: String
        let normalisedSize: String
        let location: String?
        let memory: MemoryRecord
    }

    private enum MemoryCorrection {
        case replace(oldValue: String, newValue: String)
        case rewrite(String)
    }
}
