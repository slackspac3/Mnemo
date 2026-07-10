import Foundation
import MnemoCore

public struct MemoryTextNormalizer: Sendable {
    public typealias Generator = @Sendable (_ prompt: String, _ maxTokens: Int) async throws -> String?

    private let generator: Generator

    public init(foundationLoader: FoundationModelLoader = .shared) {
        self.generator = { prompt, maxTokens in
            try await foundationLoader.generate(prompt: prompt, maxTokens: maxTokens)
        }
    }

    public init(generator: @escaping Generator) {
        self.generator = generator
    }

    public func normalize(
        rawInput: String,
        extractionResult: ExtractionResult
    ) async -> ExtractionResult {
        let baseline = Self.preferredBaseline(
            rawInput: rawInput,
            extractedSummary: extractionResult.summary,
            memoryType: extractionResult.memoryType
        )
        guard !baseline.isEmpty else { return extractionResult }

        let reconciled = Self.reconcileSourceCasing(rawInput: rawInput, summary: baseline)
        var proposal = Self.deterministicProposal(
            rawInput: rawInput,
            originalSummary: baseline,
            reconciledSummary: reconciled
        )

        do {
            let deterministicSummary = proposal.proposedSummary
            if let response = try await generator(Self.prompt(rawInput: rawInput, summary: deterministicSummary), 420),
               let modelProposal = Self.parse(response: response, originalSummary: deterministicSummary),
               Self.isFaithful(original: deterministicSummary, proposed: modelProposal.proposedSummary) {
                proposal = Self.merge(
                    deterministic: proposal,
                    model: modelProposal,
                    baseline: baseline
                )
            }
        } catch {
            // Deterministic review remains available when the on-device model is unavailable.
        }

        return ExtractionResult(
            summary: proposal.proposedSummary,
            memoryType: extractionResult.memoryType,
            persistenceScore: extractionResult.persistenceScore,
            suggestedExpiry: extractionResult.suggestedExpiry,
            confidence: extractionResult.confidence,
            processingTier: extractionResult.processingTier,
            modalityThresholdUsed: extractionResult.modalityThresholdUsed,
            tags: extractionResult.tags,
            normalizationProposal: proposal
        )
    }

    private struct ModelResponse: Decodable {
        struct Correction: Decodable {
            let original: String
            let replacement: String
            let kind: String
            let confidence: Double
            let reason: String
        }

        let proposedSummary: String
        let corrections: [Correction]
        let requiresClarification: Bool
        let clarificationQuestion: String?
    }

    private static func prompt(rawInput: String, summary: String) -> String {
        """
        You review a private memory before it is saved on the user's device.
        Correct only spelling, capitalization, and punctuation. Return only JSON.

        Original capture: \(rawInput)
        Draft summary: \(summary)

        Recognize proper names across these categories when context supports them:
        people; countries and territories; cities, districts, streets and landmarks;
        restaurants, hotels, shops and venues; companies, brands and products;
        schools, hospitals and organisations; events, titles, airports and airlines.
        Preserve intentional brand casing, acronyms, diacritics, apostrophes and hyphens.

        Never change facts, wording, meaning, negation, quantities, dates, times, units,
        prices, phone numbers, URLs, email addresses, handles, usernames, passwords,
        flight numbers, model numbers, reference codes, or identifiers.
        Do not guess an unusual person's or venue's spelling. If a capitalization or
        spelling change is contextually ambiguous, keep the draft unchanged and ask
        one short clarification question.

        Return exactly:
        {
          "proposedSummary": "draft with orthographic corrections only",
          "corrections": [
            {
              "original": "exact text changed",
              "replacement": "exact replacement",
              "kind": "capitalization|spelling|punctuation|ambiguous",
              "confidence": 0.0,
              "reason": "short user-facing reason"
            }
          ],
          "requiresClarification": false,
          "clarificationQuestion": null
        }
        """
    }

    private static func preferredBaseline(
        rawInput: String,
        extractedSummary: String,
        memoryType: MemoryType
    ) -> String {
        let original = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let extracted = extractedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !original.isEmpty else { return extracted }

        let lineCount = original.split(whereSeparator: \Character.isNewline).count
        let sentenceEndCount = original.reduce(into: 0) { count, character in
            if ".!?".contains(character) { count += 1 }
        }

        if memoryType == .credential || !protectedValues(in: original).isEmpty {
            return original
        }
        if original.count <= 240, lineCount <= 2, sentenceEndCount <= 2 {
            return original
        }
        return extracted.isEmpty ? String(original.prefix(240)) : extracted
    }

    private static func deterministicProposal(
        rawInput: String,
        originalSummary: String,
        reconciledSummary: String
    ) -> MemoryNormalizationProposal {
        var proposed = reconciledSummary
        var corrections = sourceCasingCorrections(
            originalSummary: originalSummary,
            reconciledSummary: reconciledSummary
        )

        if let firstToken = tokens(in: proposed).first,
           let firstCharacter = firstToken.text.first,
           firstCharacter.isLowercase {
            let replacement = String(firstCharacter).uppercased(with: Locale.current) + String(firstToken.text.dropFirst())
            proposed.replaceSubrange(firstToken.range, with: replacement)
            corrections.append(
                MemoryCorrection(
                    original: firstToken.text,
                    replacement: replacement,
                    kind: .capitalization,
                    confidence: 1.0,
                    reason: "Sentence capitalization"
                )
            )
        }

        corrections.append(contentsOf: capitalizationCorrections(
            rawInput: rawInput,
            proposedSummary: proposed,
            excluding: corrections
        ))

        return MemoryNormalizationProposal(
            originalSummary: originalSummary,
            proposedSummary: proposed,
            corrections: deduplicated(corrections)
        )
    }

    private static func reconcileSourceCasing(rawInput: String, summary: String) -> String {
        let sourceTokens = tokens(in: rawInput)
        let canonicalByLowercase = Dictionary(grouping: sourceTokens, by: lowercaseKey)
            .compactMapValues { variants -> String? in
                let distinctive = Set(variants.map(\.text).filter(hasDistinctiveCasing))
                return distinctive.count == 1 ? distinctive.first : nil
            }

        var result = summary
        for token in tokens(in: summary).reversed() {
            let key = lowercaseKey(token)
            guard let canonical = canonicalByLowercase[key], canonical != token.text else { continue }
            result.replaceSubrange(token.range, with: canonical)
        }
        return result
    }

    private static func sourceCasingCorrections(
        originalSummary: String,
        reconciledSummary: String
    ) -> [MemoryCorrection] {
        let before = tokens(in: originalSummary)
        let after = tokens(in: reconciledSummary)
        guard before.count == after.count else { return [] }

        return zip(before, after).compactMap { old, new in
            guard old.text != new.text, lowercaseKey(old) == lowercaseKey(new) else { return nil }
            return MemoryCorrection(
                original: old.text,
                replacement: new.text,
                kind: .sourcePreservation,
                confidence: 1.0,
                reason: "Preserved capitalization from the original capture"
            )
        }
    }

    private static func capitalizationCorrections(
        rawInput: String,
        proposedSummary: String,
        excluding existing: [MemoryCorrection]
    ) -> [MemoryCorrection] {
        let existingPairs = Set(existing.map { "\($0.original)|\($0.replacement)" })
        let proposedByKey = Dictionary(grouping: tokens(in: proposedSummary), by: lowercaseKey)
        var result: [MemoryCorrection] = []

        for original in tokens(in: rawInput) where !hasDistinctiveCasing(original) {
            guard let candidates = proposedByKey[lowercaseKey(original)],
                  let replacement = candidates.map(\.text).first(where: hasDistinctiveCasing),
                  replacement != original.text,
                  !existingPairs.contains("\(original.text)|\(replacement)") else { continue }

            result.append(
                MemoryCorrection(
                    original: original.text,
                    replacement: replacement,
                    kind: .capitalization,
                    confidence: 0.95,
                    reason: "Possible proper name"
                )
            )
        }
        return result
    }

    private static func parse(response: String, originalSummary: String) -> MemoryNormalizationProposal? {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let raw = try? JSONDecoder().decode(ModelResponse.self, from: data) else { return nil }

        let proposed = raw.proposedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !proposed.isEmpty else { return nil }

        let corrections = raw.corrections.compactMap { item -> MemoryCorrection? in
            guard !item.original.isEmpty,
                  !item.replacement.isEmpty,
                  originalSummary.localizedCaseInsensitiveContains(item.original),
                  proposed.localizedCaseInsensitiveContains(item.replacement),
                  let kind = MemoryCorrection.Kind(rawValue: item.kind),
                  kind != .sourcePreservation else { return nil }

            return MemoryCorrection(
                original: item.original,
                replacement: item.replacement,
                kind: kind,
                confidence: item.confidence,
                reason: item.reason
            )
        }

        return MemoryNormalizationProposal(
            originalSummary: originalSummary,
            proposedSummary: proposed,
            corrections: corrections,
            requiresClarification: raw.requiresClarification,
            clarificationQuestion: raw.requiresClarification ? raw.clarificationQuestion : nil
        )
    }

    private static func merge(
        deterministic: MemoryNormalizationProposal,
        model: MemoryNormalizationProposal,
        baseline: String
    ) -> MemoryNormalizationProposal {
        var corrections = deterministic.corrections + model.corrections
        if model.proposedSummary != model.originalSummary, model.corrections.isEmpty {
            corrections.append(
                MemoryCorrection(
                    original: model.originalSummary,
                    replacement: model.proposedSummary,
                    kind: .spelling,
                    confidence: 0.5,
                    reason: "Review Mnemo's suggested wording"
                )
            )
        }

        return MemoryNormalizationProposal(
            originalSummary: baseline,
            proposedSummary: model.proposedSummary,
            corrections: deduplicated(corrections),
            requiresClarification: model.requiresClarification,
            clarificationQuestion: model.clarificationQuestion
        )
    }

    static func isFaithful(original: String, proposed: String) -> Bool {
        let originalTrimmed = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let proposedTrimmed = proposed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !originalTrimmed.isEmpty, !proposedTrimmed.isEmpty else { return false }

        let protected = protectedValues(in: originalTrimmed)
        guard protected.allSatisfy({ proposedTrimmed.contains($0) }) else { return false }

        let proposedTokens = Dictionary(grouping: tokens(in: proposedTrimmed), by: lowercaseKey)
        for token in tokens(in: originalTrimmed) where hasDistinctiveCasing(token) {
            guard let matches = proposedTokens[lowercaseKey(token)],
                  matches.contains(where: { $0.text == token.text }) else { return false }
        }

        let originalNegation = negationTokens(in: originalTrimmed)
        let proposedNegation = negationTokens(in: proposedTrimmed)
        guard originalNegation == proposedNegation else { return false }

        let lhs = comparisonForm(originalTrimmed)
        let rhs = comparisonForm(proposedTrimmed)
        let allowedDistance = max(4, Int(Double(max(lhs.count, rhs.count)) * 0.18))
        return levenshteinDistance(lhs, rhs) <= allowedDistance
    }

    private static func protectedValues(in text: String) -> [String] {
        let patterns = [
            #"https?://[^\s]+"#,
            #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            #"(?<!\w)@[\p{L}\p{N}._-]+"#,
            #"\b[\p{L}]*\d[\p{L}\p{N}:/.,+-]*\b"#
        ]

        return patterns.flatMap { pattern -> [String] in
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            ) else { return [] }
            let range = NSRange(text.startIndex..., in: text)
            return regex.matches(in: text, range: range).compactMap { match in
                Range(match.range, in: text).map { String(text[$0]) }
            }
        }
    }

    private static func negationTokens(in text: String) -> [String: Int] {
        let negations: Set<String> = [
            "no", "not", "never", "none", "without", "cannot", "can't", "cant",
            "don't", "dont", "doesn't", "doesnt", "didn't", "didnt", "won't", "wont"
        ]
        return Dictionary(grouping: tokens(in: text).map(lowercaseKey).filter(negations.contains), by: { $0 })
            .mapValues(\.count)
    }

    private struct Token {
        let text: String
        let range: Range<String.Index>
    }

    private static func tokens(in text: String) -> [Token] {
        guard let regex = try? NSRegularExpression(
            pattern: #"[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N}'’.-]*"#
        ) else { return [] }
        let fullRange = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: fullRange).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return Token(text: String(text[range]), range: range)
        }
    }

    private static func lowercaseKey(_ token: Token) -> String {
        token.text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func hasDistinctiveCasing(_ token: Token) -> Bool {
        hasDistinctiveCasing(token.text)
    }

    private static func hasDistinctiveCasing(_ text: String) -> Bool {
        text.contains(where: \Character.isUppercase)
    }

    private static func comparisonForm(_ text: String) -> [Character] {
        Array(text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current))
    }

    private static func levenshteinDistance(_ lhs: [Character], _ rhs: [Character]) -> Int {
        guard !lhs.isEmpty else { return rhs.count }
        guard !rhs.isEmpty else { return lhs.count }

        var previous = Array(0...rhs.count)
        for (leftIndex, left) in lhs.enumerated() {
            var current = [leftIndex + 1]
            for (rightIndex, right) in rhs.enumerated() {
                current.append(min(
                    current[rightIndex] + 1,
                    previous[rightIndex + 1] + 1,
                    previous[rightIndex] + (left == right ? 0 : 1)
                ))
            }
            previous = current
        }
        return previous[rhs.count]
    }

    private static func deduplicated(_ corrections: [MemoryCorrection]) -> [MemoryCorrection] {
        var seen = Set<String>()
        return corrections.filter { seen.insert($0.id).inserted }
    }
}
