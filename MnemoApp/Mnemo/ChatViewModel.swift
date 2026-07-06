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

    init() {
        messages.append(Message(
            role: .assistant,
            content: "Hi. I'm Mnemo. Tell me things you want to remember, or ask me anything you've already told me."
        ))
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
        let sizeMemories = citedMemories.filter { memory in
            extractSizeFact(from: searchableText(for: memory), memory: memory) != nil
        }
        guard !sizeMemories.isEmpty else {
            return RecallResponse(
                text: "I found the memory you were referring to, but I could not find a size in it to update.",
                citedMemoryIds: citedMemories.map(\.id),
                citations: citations(for: citedMemories)
            )
        }

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
        let location = extractLocation(from: searchableText(for: firstMemory))
        let item = itemLabel(for: searchableText(for: firstMemory))
        let subject = sizeSubject(item: item, location: location)

        return RecallResponse(
            text: "Updated. Your \(subject) is now \(displaySize).",
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
        guard !memories.isEmpty else {
            return RecallResponse(
                text: "I do not have any saved memories yet. Save something first, then ask me again.",
                citedMemoryIds: []
            )
        }

        let ranked = memories
            .map { memory in
                RankedMemory(
                    memory: memory,
                    score: score(memory: memory, query: query),
                    matchedTerms: matchedTerms(memory: memory, query: query)
                )
            }
            .filter { $0.score > 0.08 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.memory.createdAt > rhs.memory.createdAt
                }
                return lhs.score > rhs.score
            }

        let topMatches = Array(ranked.prefix(3))
        guard !topMatches.isEmpty else {
            return RecallResponse(
                text: "I could not find a saved memory that matched that. Try asking with a specific name, place, or detail you remember saving.",
                citedMemoryIds: []
            )
        }

        return RecallResponse(
            text: responseText(for: topMatches, query: query),
            citedMemoryIds: topMatches.map { $0.memory.id },
            citations: citations(for: topMatches.map(\.memory))
        )
    }

    private func score(memory: MemoryRecord, query: String) -> Double {
        let queryTokens = meaningfulTokens(in: query)
        guard !queryTokens.isEmpty else {
            return isRecentMemoryQuery(query) ? recencyScore(for: memory) : 0
        }

        let memoryText = searchableText(for: memory)
        let memoryTokens = meaningfulTokens(in: memoryText)
        guard !memoryTokens.isEmpty else { return 0 }

        let overlap = queryTokens.intersection(memoryTokens)
        guard !overlap.isEmpty else { return 0 }

        let lexicalScore = Double(overlap.count) / Double(queryTokens.count)
        let embeddingScore = cosine(
            EmbeddingHelper.shared.embed(query),
            EmbeddingHelper.shared.embed(memoryText)
        )
        let confidenceBoost = min(max(memory.confidence, 0), 1) * 0.05
        let persistenceBoost = min(max(memory.persistenceScore, 0), 1) * 0.05

        return (lexicalScore * 0.80) + (embeddingScore * 0.10) + confidenceBoost + persistenceBoost
    }

    private func responseText(for matches: [RankedMemory], query: String) -> String {
        if isRecentMemoryQuery(query), let match = matches.first {
            return """
            You most recently saved:
            "\(summaryLine(for: match.memory))"
            """
        }

        if let answer = directAnswer(for: query, using: matches) {
            return answer
        }

        if matches.count == 1, let match = matches.first {
            return """
            I found this:
            "\(summaryLine(for: match.memory))"
            """
        }

        let lines = matches.enumerated().map { index, match in
            "\(index + 1). \"\(summaryLine(for: match.memory))\""
        }

        return "I found a few possible matches:\n\n" + lines.joined(separator: "\n")
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

    private func matchedTerms(memory: MemoryRecord, query: String) -> [String] {
        let overlap = meaningfulTokens(in: query).intersection(meaningfulTokens(in: searchableText(for: memory)))
        return Array(Array(overlap).sorted().prefix(4))
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
            #"\b(?:update|change|set|make)\b.*\b(?:to|as)\s+(xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b"#,
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
        messages.reversed().first { message in
            message.role == .assistant && !message.citedMemoryIds.isEmpty
        }?.citedMemoryIds ?? []
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

    private func directAnswer(for query: String, using matches: [RankedMemory]) -> String? {
        let lowercasedQuery = query.lowercased()
        if lowercasedQuery.contains("where"),
           let memory = matches.first?.memory,
           let location = extractLocation(from: searchableText(for: memory)) {
            return """
            It was in \(location).

            I found that in:
            "\(summaryLine(for: memory))"
            """
        }

        if isSizeQuery(query),
           let answer = sizeAnswer(for: query, using: matches) {
            return answer
        }

        return nil
    }

    private func sizeAnswer(for query: String, using matches: [RankedMemory]) -> String? {
        let facts = matches.compactMap { match in
            extractSizeFact(from: searchableText(for: match.memory), memory: match.memory)
        }
        guard let first = facts.first else { return nil }

        let uniqueSizes = Set(facts.map(\.normalisedSize))
        let chosen = facts.first { fact in
            fact.normalisedSize == first.normalisedSize && fact.displaySize.count <= 3
        } ?? first

        let item = itemLabel(for: query)
        let location = chosen.location ?? extractLocation(from: query)
        let subject = sizeSubject(
            item: item,
            location: location,
            query: query,
            memoryText: searchableText(for: chosen.memory)
        )

        if uniqueSizes.count > 1 {
            return """
            I found a couple of saved sizes.
            The most recent one says your \(subject) is \(chosen.displaySize).

            I found that in:
            "\(summaryLine(for: chosen.memory))"
            """
        }

        return """
        Your \(subject) is \(chosen.displaySize).

        I found that in:
        "\(summaryLine(for: chosen.memory))"
        """
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

    private func isSizeQuery(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("size") ||
            lowercased.contains("shirt") ||
            lowercased.contains("clothes") ||
            lowercased.contains("clothing") ||
            lowercased.contains("wear")
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

    private func tokens(in text: String) -> Set<String> {
        let words = text.lowercased().split { character in
            !character.isLetter && !character.isNumber
        }
        return Set(words.flatMap { tokenVariants(for: String($0)) }.filter { $0.count > 2 })
    }

    private func tokenVariants(for token: String) -> Set<String> {
        var variants: Set<String> = [token]

        if token.count > 4, token.hasSuffix("s") {
            variants.insert(String(token.dropLast()))
        }

        if token.count > 4, token.hasSuffix("ed") {
            variants.insert(String(token.dropLast()))
            variants.insert(String(token.dropLast(2)))
        }

        if token.count > 5, token.hasSuffix("ing") {
            variants.insert(String(token.dropLast(3)))
        }

        return variants
    }

    private func meaningfulTokens(in text: String) -> Set<String> {
        tokens(in: text).subtracting(Self.stopWords)
    }

    private func isRecentMemoryQuery(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("just save") ||
            lowercased.contains("last save") ||
            lowercased.contains("recent memory") ||
            lowercased.contains("latest memory") ||
            lowercased.contains("most recently") ||
            lowercased.contains("recently save") ||
            lowercased.contains("recently saved")
    }

    private func recencyScore(for memory: MemoryRecord) -> Double {
        let age = abs(memory.createdAt.timeIntervalSinceNow)
        return max(0.1, 1 - min(age / 86_400, 1))
    }

    private func cosine(_ lhs: [Float], _ rhs: [Float]) -> Double {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }

        let dot = zip(lhs, rhs).map(*).reduce(0, +)
        let lhsMagnitude = sqrt(lhs.map { $0 * $0 }.reduce(0, +))
        let rhsMagnitude = sqrt(rhs.map { $0 * $0 }.reduce(0, +))
        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }

        return Double(dot / (lhsMagnitude * rhsMagnitude))
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

    private struct RankedMemory {
        let memory: MemoryRecord
        let score: Double
        let matchedTerms: [String]
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

    private static let stopWords: Set<String> = [
        "about",
        "after",
        "again",
        "already",
        "also",
        "anything",
        "asked",
        "before",
        "could",
        "did",
        "does",
        "for",
        "from",
        "had",
        "have",
        "how",
        "just",
        "know",
        "last",
        "latest",
        "memory",
        "much",
        "remember",
        "said",
        "save",
        "saved",
        "tell",
        "that",
        "the",
        "this",
        "was",
        "were",
        "what",
        "when",
        "where",
        "which",
        "who",
        "why",
        "with",
        "you"
    ]
}
