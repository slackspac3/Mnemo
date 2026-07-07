import Foundation

/// Deterministic V1 recall over locally saved memories.
///
/// This intentionally avoids cloud calls, LLMs, or production semantic claims. It
/// combines lexical matching, small synonym expansion, category hints, recency,
/// and the placeholder character embedding as a weak helper signal.
public struct RecallEngine {

    private let embeddingHelper: EmbeddingHelper

    public init(embeddingHelper: EmbeddingHelper = .shared) {
        self.embeddingHelper = embeddingHelper
    }

    @MainActor
    public func recall(query: String, memories: [MemoryRecord]) -> RecallResult {
        let activeMemories = memories.filter { !$0.isArchived }
        guard !activeMemories.isEmpty else {
            return RecallResult(
                text: "I do not have any saved memories yet. Save something first, then ask me again.",
                citedMemoryIds: [],
                citations: []
            )
        }

        if isRecentMemoryQuery(query),
           let latest = activeMemories.sorted(by: { $0.createdAt > $1.createdAt }).first {
            return result(
                text: """
                You most recently saved:
                "\(summaryLine(for: latest))"
                """,
                memories: [latest]
            )
        }

        if let guardedResult = guardedPrecisionResult(for: query, memories: activeMemories) {
            return guardedResult
        }

        let ranked = activeMemories
            .map { memory in
                RankedMemory(
                    memory: memory,
                    score: score(memory: memory, query: query)
                )
            }
            .filter { $0.score >= 0.12 }
            .sorted { lhs, rhs in
                if abs(lhs.score - rhs.score) < 0.0001 {
                    return lhs.memory.createdAt > rhs.memory.createdAt
                }
                return lhs.score > rhs.score
            }

        let topMatches = Array(ranked.prefix(3))
        guard !topMatches.isEmpty else {
            return RecallResult(
                text: "I could not find a saved memory that matched that. Try asking with a specific name, place, or detail you remember saving.",
                citedMemoryIds: [],
                citations: []
            )
        }

        let draft = responseDraft(for: topMatches, query: query)
        return result(text: draft.text, memories: draft.citedMemories)
    }

    // MARK: - Ranking

    private func score(memory: MemoryRecord, query: String) -> Double {
        let queryTokens = meaningfulTokens(in: query, expandingSynonyms: true)
        guard !queryTokens.isEmpty else { return 0 }

        let memoryText = searchableText(for: memory)
        let memoryTokens = meaningfulTokens(in: memoryText, expandingSynonyms: true)
        guard !memoryTokens.isEmpty else { return 0 }

        let overlap = queryTokens.intersection(memoryTokens)
        let lexicalScore = Double(overlap.count) / Double(queryTokens.count)
        let embeddingScore = cosine(
            embeddingHelper.embed(query),
            embeddingHelper.embed(memoryText)
        )
        let numberBoost = numberScore(query: query, memoryText: memoryText)
        let phraseBoost = phraseScore(query: query, memoryText: memoryText)
        let categoryBoost = categoryScore(query: query, memoryText: memoryText)
        let personBoost = personScore(query: query, memoryText: memoryText)
        let forgetIntentBoost = forgetShoppingScore(query: query, memoryText: memoryText)
        let confidenceBoost = min(max(memory.confidence, 0), 1) * 0.03
        let persistenceBoost = min(max(memory.persistenceScore, 0), 1) * 0.03

        let score = (lexicalScore * 0.72) +
            (embeddingScore * 0.06) +
            numberBoost +
            phraseBoost +
            categoryBoost +
            personBoost +
            forgetIntentBoost +
            confidenceBoost +
            persistenceBoost

        return max(0, score)
    }

    private func numberScore(query: String, memoryText: String) -> Double {
        let queryNumbers = numbers(in: query)
        guard !queryNumbers.isEmpty else { return 0 }
        let memoryNumbers = numbers(in: memoryText)
        return queryNumbers.intersection(memoryNumbers).isEmpty ? 0 : 0.18
    }

    private func phraseScore(query: String, memoryText: String) -> Double {
        let queryTerms = meaningfulTokens(in: query, expandingSynonyms: false)
        guard queryTerms.count >= 2 else { return 0 }
        let memoryTerms = meaningfulTokens(in: memoryText, expandingSynonyms: false)
        let overlap = queryTerms.intersection(memoryTerms)
        return overlap.count >= min(2, queryTerms.count) ? 0.10 : 0
    }

    private func categoryScore(query: String, memoryText: String) -> Double {
        let queryCategories = categories(in: query)
        guard !queryCategories.isEmpty else { return 0 }
        return queryCategories.intersection(categories(in: memoryText)).isEmpty ? 0 : 0.12
    }

    private func personScore(query: String, memoryText: String) -> Double {
        let queryNames = notableTerms(in: query)
        guard !queryNames.isEmpty else { return 0 }
        let memoryNames = notableTerms(in: memoryText)
        return queryNames.intersection(memoryNames).isEmpty ? 0 : 0.14
    }

    private func forgetShoppingScore(query: String, memoryText: String) -> Double {
        guard hasForgetIntent(query),
              categories(in: query).contains("shopping")
        else { return 0 }

        if hasForgetIntent(memoryText) {
            return 0.24
        }

        return categories(in: memoryText).contains("shopping") ? -0.10 : 0
    }

    // MARK: - Answers

    private func responseDraft(for matches: [RankedMemory], query: String) -> ResponseDraft {
        if let answer = directAnswer(for: query, using: matches) {
            return answer
        }

        if matches.count == 1, let match = matches.first {
            return ResponseDraft(
                text: summaryLine(for: match.memory),
                citedMemories: [match.memory]
            )
        }

        let lines = matches.enumerated().map { index, match in
            "\(index + 1). \"\(summaryLine(for: match.memory))\""
        }

        return ResponseDraft(
            text: "I found a few possible matches:\n\n" + lines.joined(separator: "\n"),
            citedMemories: matches.map(\.memory)
        )
    }

    private func directAnswer(for query: String, using matches: [RankedMemory]) -> ResponseDraft? {
        let lowercasedQuery = query.lowercased()
        if isDateQuery(query),
           let answer = dateAnswer(for: query, using: matches) {
            return answer
        }

        if isParkingQuery(query),
           let memory = matches.first?.memory,
           let parkingLocation = extractParkingLocation(from: searchableText(for: memory)) {
            return ResponseDraft(
                text: "\(parkingLocation).",
                citedMemories: [memory]
            )
        }

        if lowercasedQuery.contains("where"),
           let memory = matches.first?.memory,
           let location = extractLocation(from: searchableText(for: memory)) {
            return ResponseDraft(
                text: "It was in \(location).",
                citedMemories: [memory]
            )
        }

        if isSizeQuery(query),
           let answer = sizeAnswer(for: query, using: matches) {
            return answer
        }

        return nil
    }

    private func dateAnswer(for query: String, using matches: [RankedMemory]) -> ResponseDraft? {
        for match in matches {
            let memory = match.memory
            guard let resolution = resolveDate(from: searchableText(for: memory), referenceDate: memory.createdAt) else {
                continue
            }

            return ResponseDraft(
                text: """
                By \(formattedDate(resolution.date)).

                I calculated that from "\(resolution.evidence)" in the saved memory.
                """,
                citedMemories: [memory]
            )
        }

        return nil
    }

    private func sizeAnswer(for query: String, using matches: [RankedMemory]) -> ResponseDraft? {
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
            return ResponseDraft(
                text: """
                I found a couple of saved sizes.
                The most recent one says \(sizeSentence(subject: subject, displaySize: chosen.displaySize)).
                """,
                citedMemories: uniqueMemories(facts.map(\.memory))
            )
        }

        return ResponseDraft(
            text: "\(capitalizedSentence(sizeSentence(subject: subject, displaySize: chosen.displaySize))).",
            citedMemories: [chosen.memory]
        )
    }

    // MARK: - Text extraction

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

    private func guardedPrecisionResult(for query: String, memories: [MemoryRecord]) -> RecallResult? {
        if let result = passportNumberGuard(for: query, memories: memories) {
            return result
        }

        if let result = birthdayGuard(for: query, memories: memories) {
            return result
        }

        if let result = homeWifiGuard(for: query, memories: memories) {
            return result
        }

        if let result = personSizeGuard(for: query, memories: memories) {
            return result
        }

        if let result = sizeVariantGuard(for: query, memories: memories) {
            return result
        }

        return nil
    }

    private func passportNumberGuard(for query: String, memories: [MemoryRecord]) -> RecallResult? {
        let lowercasedQuery = query.lowercased()
        guard lowercasedQuery.contains("passport"),
              lowercasedQuery.contains("number")
        else { return nil }

        let passportNumberMemories = memories.filter { memory in
            let text = searchableText(for: memory).lowercased()
            return text.contains("passport") &&
                (text.contains("passport number") ||
                    text.contains("passport no") ||
                    text.contains("passport #"))
        }
        if !passportNumberMemories.isEmpty {
            return nil
        }

        if memories.contains(where: { searchableText(for: $0).lowercased().contains("passport") }) {
            return RecallResult(
                text: "I do not have a passport number saved. I found a passport memory, but it does not contain a passport number.",
                citedMemoryIds: [],
                citations: []
            )
        }

        return nil
    }

    private func birthdayGuard(for query: String, memories: [MemoryRecord]) -> RecallResult? {
        guard let subject = birthdaySubject(in: query) else { return nil }

        let matchingBirthdayMemories = memories.filter { memory in
            let tokens = meaningfulTokens(in: searchableText(for: memory), expandingSynonyms: false)
            return tokens.contains(subject) && tokens.contains("birthday")
        }
        if !matchingBirthdayMemories.isEmpty {
            return nil
        }

        return RecallResult(
            text: "I do not have \(subject.capitalized)'s birthday saved.",
            citedMemoryIds: [],
            citations: []
        )
    }

    private func homeWifiGuard(for query: String, memories: [MemoryRecord]) -> RecallResult? {
        let lowercasedQuery = query.lowercased()
        guard lowercasedQuery.contains("wi-fi") || lowercasedQuery.contains("wifi"),
              lowercasedQuery.contains("password"),
              lowercasedQuery.contains("home")
        else { return nil }

        let homeWifiMemories = memories.filter { memory in
            let text = searchableText(for: memory).lowercased()
            return (text.contains("wi-fi") || text.contains("wifi")) &&
                text.contains("password") &&
                text.contains("home")
        }
        if !homeWifiMemories.isEmpty {
            return nil
        }

        guard let otherWifiMemory = memories.first(where: { memory in
            let text = searchableText(for: memory).lowercased()
            return (text.contains("wi-fi") || text.contains("wifi")) && text.contains("password")
        }) else { return nil }

        let place = wifiPlace(in: searchableText(for: otherWifiMemory)) ?? "another place"
        return result(
            text: "I do not have a home Wi-Fi password saved. I found a \(place) Wi-Fi password, but that may be different.",
            memories: [otherWifiMemory]
        )
    }

    private func personSizeGuard(for query: String, memories: [MemoryRecord]) -> RecallResult? {
        guard let subject = sizePersonSubject(in: query) else { return nil }

        let matchingSizeMemories = memories.filter { memory in
            let memoryText = searchableText(for: memory)
            let tokens = meaningfulTokens(in: memoryText, expandingSynonyms: false)
            return tokens.contains(subject) &&
                extractSizeFact(from: memoryText, memory: memory) != nil
        }
        if !matchingSizeMemories.isEmpty {
            return nil
        }

        return RecallResult(
            text: "I do not have \(displayName(for: subject))'s size saved.",
            citedMemoryIds: [],
            citations: []
        )
    }

    private func sizeVariantGuard(for query: String, memories: [MemoryRecord]) -> RecallResult? {
        guard isSizeQuery(query),
              let requestedVariant = sizeVariant(in: query)
        else { return nil }

        let queryTokens = meaningfulTokens(in: query, expandingSynonyms: false)
        let sizeMemories = memories.filter { memory in
            let memoryText = searchableText(for: memory)
            guard isSizeQuery(memoryText),
                  queryTokens.intersection(meaningfulTokens(in: memoryText, expandingSynonyms: false)).count >= 2
            else { return false }

            return true
        }

        if sizeMemories.contains(where: { sizeVariant(in: searchableText(for: $0)) == requestedVariant }) {
            return nil
        }

        guard let mismatchedMemory = sizeMemories.first(where: { memory in
            guard let memoryVariant = sizeVariant(in: searchableText(for: memory)) else { return false }
            return memoryVariant != requestedVariant
        }) else { return nil }

        let foundVariant = sizeVariant(in: searchableText(for: mismatchedMemory)) ?? "another"
        let item = itemLabel(for: query)
        let location = extractLocation(from: searchableText(for: mismatchedMemory)) ?? extractLocation(from: query)
        let subject = sizeSubject(
            item: item,
            location: location,
            query: query,
            memoryText: searchableText(for: mismatchedMemory)
        )

        return result(
            text: "I do not have your \(requestedVariant) \(subject) saved. I found a \(foundVariant) \(subject), but that may not be the same.",
            memories: [mismatchedMemory]
        )
    }

    private func extractSizeFact(from text: String, memory: MemoryRecord) -> SizeFact? {
        let patterns: [(pattern: String, sizeGroup: Int, locationGroup: Int?)] = [
            (#"\b(?:size\s+)?(?:is|=|:)\s*(xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b"#, 1, nil),
            (#"\bwears?\s+(?:a\s+)?(?:size\s+)?(xxs|xs|s|m|l|xl|xxl|small|medium|large|\d{1,3})\b"#, 1, nil),
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

    private func extractLocation(from text: String) -> String? {
        let patterns = [
            #"\b(?:in|at|near)\s+([^.,;\n]+)"#,
            #"\bthe\s+([A-Za-z][A-Za-z\s'-]{1,40})\s+waterfall\b"#,
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
                return phrase.capitalized
            }
        }

        return nil
    }

    private func extractParkingLocation(from text: String) -> String? {
        let patterns = [
            #"\bparking spot at [^.,;\n]+ was ([^.;\n]+)"#,
            #"\bparked at [^.,;\n]+ in ([^.;\n]+)"#,
            #"\bparking was ([^.;\n]+)"#,
            #"\bspot was ([^.;\n]+)"#,
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

            let detail = cleanParkingLocation(String(text[matchRange]))
            if !detail.isEmpty {
                return detail
            }
        }

        return nil
    }

    private func cleanParkingLocation(_ phrase: String) -> String {
        String(phrase)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'?.!"))
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

    // MARK: - Query intent

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

    private func isDateQuery(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("date") ||
            lowercased.contains("when") ||
            lowercased.contains("deadline") ||
            lowercased.contains("due") ||
            lowercased.contains("deliver") ||
            lowercased.contains("delivery") ||
            lowercased.contains("finish") ||
            lowercased.contains("complete") ||
            lowercased.contains("submit")
    }

    private func isSizeQuery(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("size") ||
            lowercased.contains("shirt") ||
            lowercased.contains("clothes") ||
            lowercased.contains("clothing") ||
            lowercased.contains("wear")
    }

    private func isParkingQuery(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("park") ||
            lowercased.contains("parking") ||
            lowercased.contains("car")
    }

    private func birthdaySubject(in query: String) -> String? {
        let pattern = #"\b([A-Za-z][A-Za-z-]+)(?:'s)?\s+birthday\b"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(query.startIndex..<query.endIndex, in: query)
            if let match = regex.firstMatch(in: query, range: range),
               let subjectRange = Range(match.range(at: 1), in: query) {
                return String(query[subjectRange]).lowercased()
            }
        }

        let tokens = Array(meaningfulTokens(in: query, expandingSynonyms: false))
        guard tokens.contains("birthday") else { return nil }
        let nonSubjectTerms: Set<String> = ["birthday", "birthdays", "date"]
        return tokens
            .filter { !nonSubjectTerms.contains($0) }
            .sorted()
            .first
    }

    private func hasForgetIntent(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return lowercased.contains("forget") ||
            lowercased.contains("forgot") ||
            lowercased.contains("remember to")
    }

    private func wifiPlace(in text: String) -> String? {
        let lowercased = text.lowercased()
        if lowercased.contains("beach house") {
            return "beach house"
        }
        if lowercased.contains("office") {
            return "office"
        }
        if lowercased.contains("hotel") {
            return "hotel"
        }
        return extractLocation(from: text)?.lowercased()
    }

    private func sizePersonSubject(in query: String) -> String? {
        guard isSizeQuery(query) else { return nil }

        let patterns = [
            #"\bwhat\s+size\s+does\s+([A-Za-z][A-Za-z-]+)\s+wear\b"#,
            #"\b([A-Za-z][A-Za-z-]+)(?:'s)?\s+(?:shoe\s+|shirt\s+|t-shirt\s+|t\s+shirt\s+)?size\b"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(query.startIndex..<query.endIndex, in: query)
            guard let match = regex.firstMatch(in: query, range: range),
                  let subjectRange = Range(match.range(at: 1), in: query)
            else { continue }

            let subject = String(query[subjectRange]).lowercased()
            if !Self.genericSizeSubjects.contains(subject) {
                return subject
            }
        }

        return nil
    }

    private func sizeVariant(in text: String) -> String? {
        let lowercased = text.lowercased()
        if lowercased.contains("loose-fit") ||
            lowercased.contains("loose fit") ||
            lowercased.contains("loosefit") {
            return "loose-fit"
        }
        if lowercased.contains("regular") {
            return "regular"
        }
        return nil
    }

    private func categories(in text: String) -> Set<String> {
        let tokens = meaningfulTokens(in: text, expandingSynonyms: true)
        var categories = Set<String>()

        if !tokens.intersection(["buy", "purchase", "shopping", "grocery", "groceries"]).isEmpty {
            categories.insert("shopping")
        }
        if !tokens.intersection(["doctor", "dermatologist", "skin", "skincare"]).isEmpty {
            categories.insert("skincare")
        }
        if !tokens.intersection(["size", "wear", "shoe", "shoes", "clothes", "clothing", "shirt", "suit"]).isEmpty {
            categories.insert("size")
        }
        if !tokens.intersection(["cancel", "subscription", "renew", "decide", "decided"]).isEmpty {
            categories.insert("decision")
        }
        if !tokens.intersection(["restaurant", "restaurants", "dinner", "food"]).isEmpty {
            categories.insert("restaurant")
        }
        if !tokens.intersection(["deadline", "due", "submit", "finish", "complete", "deliver"]).isEmpty {
            categories.insert("deadline")
        }
        if !tokens.intersection(["mum", "mom", "mother", "ahmed"]).isEmpty {
            categories.insert("person")
        }
        if !tokens.intersection(["hotel", "room", "lift", "elevator"]).isEmpty {
            categories.insert("hotel")
        }
        if tokens.contains("waterfall") || tokens.contains("falls") {
            categories.insert("place")
        }

        return categories
    }

    // MARK: - Date handling

    private func resolveDate(from text: String, referenceDate: Date) -> DateResolution? {
        if let duration = relativeDuration(in: text, referenceDate: referenceDate) {
            return duration
        }

        let lowercased = text.lowercased()
        let calendar = Calendar.autoupdatingCurrent

        if lowercased.contains("tomorrow"),
           let date = calendar.date(byAdding: .day, value: 1, to: referenceDate) {
            return DateResolution(date: date, evidence: "tomorrow")
        }

        if lowercased.contains("next week"),
           let date = calendar.date(byAdding: .day, value: 7, to: referenceDate) {
            return DateResolution(date: date, evidence: "next week")
        }

        if lowercased.contains("next month"),
           let date = calendar.date(byAdding: .month, value: 1, to: referenceDate) {
            return DateResolution(date: date, evidence: "next month")
        }

        return nil
    }

    private func relativeDuration(in text: String, referenceDate: Date) -> DateResolution? {
        let pattern = #"\b(?:in|within|after)\s+(\d{1,3}|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\s+(day|days|week|weeks|month|months)\b"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else { return nil }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 2,
              let fullRange = Range(match.range(at: 0), in: text),
              let valueRange = Range(match.range(at: 1), in: text),
              let unitRange = Range(match.range(at: 2), in: text),
              let value = durationValue(String(text[valueRange]))
        else { return nil }

        let unit = String(text[unitRange]).lowercased()
        let calendar = Calendar.autoupdatingCurrent
        let date: Date?
        if unit.hasPrefix("day") {
            date = calendar.date(byAdding: .day, value: value, to: referenceDate)
        } else if unit.hasPrefix("week") {
            date = calendar.date(byAdding: .day, value: value * 7, to: referenceDate)
        } else {
            date = calendar.date(byAdding: .month, value: value, to: referenceDate)
        }

        guard let date else { return nil }
        return DateResolution(
            date: date,
            evidence: String(text[fullRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func durationValue(_ text: String) -> Int? {
        if let number = Int(text) {
            return number
        }

        switch text.lowercased() {
        case "one": return 1
        case "two": return 2
        case "three": return 3
        case "four": return 4
        case "five": return 5
        case "six": return 6
        case "seven": return 7
        case "eight": return 8
        case "nine": return 9
        case "ten": return 10
        case "eleven": return 11
        case "twelve": return 12
        default: return nil
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Tokenisation

    private func tokens(in text: String, expandingSynonyms: Bool) -> Set<String> {
        let words = text.lowercased().split { character in
            !character.isLetter && !character.isNumber
        }
        let baseTokens = Set(words.flatMap { tokenVariants(for: String($0)) }.filter { $0.count > 2 })
        guard expandingSynonyms else { return baseTokens }

        return baseTokens.reduce(into: baseTokens) { result, token in
            if let expansions = Self.synonyms[token] {
                result.formUnion(expansions)
            }
        }
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
            let stem = String(token.dropLast(3))
            variants.insert(stem)
            if stem.count > 1,
               stem.last == stem.dropLast().last {
                variants.insert(String(stem.dropLast()))
            }
        }

        return variants
    }

    private func meaningfulTokens(in text: String, expandingSynonyms: Bool) -> Set<String> {
        tokens(in: text, expandingSynonyms: expandingSynonyms).subtracting(Self.stopWords)
    }

    private func numbers(in text: String) -> Set<String> {
        Set(text.split { !$0.isNumber }.map(String.init).filter { !$0.isEmpty })
    }

    private func notableTerms(in text: String) -> Set<String> {
        meaningfulTokens(in: text, expandingSynonyms: false)
            .filter { token in
                token.count > 3 && !Self.genericNotableTerms.contains(token)
            }
    }

    // MARK: - Size formatting

    private func itemLabel(for query: String) -> String {
        let lowercased = query.lowercased()
        if lowercased.contains("t-shirt") ||
            lowercased.contains("t shirt") ||
            lowercased.contains("shirt") {
            return "T-shirt"
        }
        if lowercased.contains("shoe") {
            return "shoe"
        }
        return "size"
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

    private func sizeSentence(subject: String, displaySize: String) -> String {
        let prefix = subject.contains("'") ? "" : "your "
        return "\(prefix)\(subject) is \(displaySize)"
    }

    private func capitalizedSentence(_ sentence: String) -> String {
        guard let first = sentence.first else { return sentence }
        return first.uppercased() + String(sentence.dropFirst())
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

    // MARK: - Helpers

    private func result(text: String, memories: [MemoryRecord]) -> RecallResult {
        RecallResult(
            text: text,
            citedMemoryIds: memories.map(\.id),
            citations: memories.map { memory in
                RecallCitation(
                    id: memory.id,
                    summary: summaryLine(for: memory),
                    source: memory.inputSource.capitalized
                )
            }
        )
    }

    private func displayName(for subject: String) -> String {
        switch subject {
        case "mum":
            return "Mum"
        case "mom":
            return "Mom"
        case "mother":
            return "Mother"
        default:
            return subject.capitalized
        }
    }

    private func uniqueMemories(_ memories: [MemoryRecord]) -> [MemoryRecord] {
        var seenIds = Set<UUID>()
        return memories.filter { memory in
            seenIds.insert(memory.id).inserted
        }
    }

    private func cosine(_ lhs: [Float], _ rhs: [Float]) -> Double {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }

        let dot = zip(lhs, rhs).map(*).reduce(0, +)
        let lhsMagnitude = sqrt(lhs.map { $0 * $0 }.reduce(0, +))
        let rhsMagnitude = sqrt(rhs.map { $0 * $0 }.reduce(0, +))
        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }

        return Double(dot / (lhsMagnitude * rhsMagnitude))
    }

    private struct RankedMemory {
        let memory: MemoryRecord
        let score: Double
    }

    private struct ResponseDraft {
        let text: String
        let citedMemories: [MemoryRecord]
    }

    private struct SizeFact {
        let displaySize: String
        let normalisedSize: String
        let location: String?
        let memory: MemoryRecord
    }

    private struct DateResolution {
        let date: Date
        let evidence: String
    }

    private static let genericNotableTerms: Set<String> = [
        "about", "always", "because", "memory", "preferred", "prefer", "recommended", "remember"
    ]

    private static let genericSizeSubjects: Set<String> = [
        "clothes",
        "clothing",
        "fit",
        "loose",
        "loose-fit",
        "regular",
        "shirt",
        "shoe",
        "shoes",
        "size",
        "tshirt",
        "wear",
        "what",
        "zara"
    ]

    private static let synonyms: [String: Set<String>] = [
        "buy": ["purchase", "shopping", "groceries", "grocery"],
        "purchase": ["buy", "shopping"],
        "shopping": ["buy", "purchase", "groceries"],
        "groceries": ["buy", "shopping", "grocery"],
        "doctor": ["dermatologist", "skin", "skincare"],
        "dermatologist": ["doctor", "skin", "skincare"],
        "skin": ["dermatologist", "skincare"],
        "skincare": ["dermatologist", "skin"],
        "size": ["wear", "clothes", "clothing", "shirt", "shoe", "shoes", "suit"],
        "wear": ["size", "clothes", "clothing", "shoe", "shoes"],
        "shoes": ["shoe", "size", "wear"],
        "shoe": ["shoes", "size", "wear"],
        "clothes": ["clothing", "size", "wear"],
        "clothing": ["clothes", "size", "wear"],
        "shirt": ["size", "clothing", "clothes"],
        "suit": ["size", "clothing", "clothes"],
        "cancel": ["subscription", "renew", "decide", "decided"],
        "decide": ["decided", "cancel"],
        "decided": ["decide", "cancel"],
        "subscription": ["cancel", "renew"],
        "renew": ["subscription", "cancel"],
        "restaurant": ["restaurants", "dinner", "food"],
        "restaurants": ["restaurant", "dinner", "food"],
        "dinner": ["restaurant", "restaurants", "food"],
        "food": ["restaurant", "restaurants", "dinner"],
        "deadline": ["due", "submit", "finish", "complete", "deliver"],
        "due": ["deadline", "submit", "finish", "complete", "deliver"],
        "submit": ["deadline", "due", "finish", "complete"],
        "finish": ["deadline", "due", "submit", "complete"],
        "complete": ["deadline", "due", "submit", "finish"],
        "deliver": ["deadline", "due", "submit", "finish", "complete"],
        "delivery": ["deadline", "due", "deliver"],
        "mum": ["mother", "mom"],
        "mom": ["mum", "mother"],
        "mother": ["mum", "mom"],
        "hotel": ["room"],
        "room": ["hotel"],
        "lift": ["elevator"],
        "elevator": ["lift"],
    ]

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
        "need",
        "needs",
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

public struct RecallResult: Equatable, Sendable {
    public let text: String
    public let citedMemoryIds: [UUID]
    public let citations: [RecallCitation]

    public init(
        text: String,
        citedMemoryIds: [UUID],
        citations: [RecallCitation]
    ) {
        self.text = text
        self.citedMemoryIds = citedMemoryIds
        self.citations = citations
    }
}

public struct RecallCitation: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let summary: String
    public let source: String

    public init(id: UUID, summary: String, source: String) {
        self.id = id
        self.summary = summary
        self.source = source
    }
}
