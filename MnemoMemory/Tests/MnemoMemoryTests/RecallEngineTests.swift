import Testing
import Foundation
@testable import MnemoMemory
import MnemoCore

@Suite("RecallEngine")
struct RecallEngineTests {

    @Test("Launch recall fixture answers and cites expected memories", arguments: recallCases)
    @MainActor
    func launchRecallFixture(testCase: RecallCase) {
        let memories = Self.launchMemories(referenceDate: referenceDate)
        let result = RecallEngine().recall(query: testCase.query, memories: memories)
        let expectedMemory = memories[testCase.expectedMemoryIndex]

        #expect(result.citedMemoryIds.first == expectedMemory.id)
        #expect(result.text.localizedCaseInsensitiveContains(testCase.expectedText))
    }

    @Test("Empty memory set fails gracefully")
    @MainActor
    func emptyMemorySet() {
        let result = RecallEngine().recall(query: "What size does mum wear?", memories: [])

        #expect(result.citedMemoryIds.isEmpty)
        #expect(result.text.localizedCaseInsensitiveContains("do not have any saved memories"))
    }

    @Test("Manual 50-query validation fixture remains passing")
    @MainActor
    func manualRecallValidationFixture() {
        let memories = ManualRecallFixture.makeMemories()
        let ids = ManualRecallFixture.idByKey(memories: memories)
        let engine = RecallEngine()

        for testCase in ManualRecallFixture.preMutationCases {
            let result = engine.recall(query: testCase.query, memories: memories)
            assert(result: result, satisfies: testCase, ids: ids)
        }

        let mum = memories.first { $0.id == ids["M02"] }!
        mum.summary = "Mum wears size 39 shoes."
        mum.rawInput = "Mum wears size 39 shoes."

        let q42 = ManualRecallFixture.ValidationCase(
            "Q42",
            query: "What size does mum wear now?",
            expectedFragments: ["39"],
            primarySource: "M02"
        )
        assert(result: engine.recall(query: q42.query, memories: memories), satisfies: q42, ids: ids)

        let candles = memories.first { $0.id == ids["M28"] }!
        candles.summary = "When buying candles, choose cedar only."
        candles.rawInput = "When buying candles, choose cedar only."

        let q44 = ManualRecallFixture.ValidationCase(
            "Q44",
            query: "What candle scent should I choose now?",
            expectedFragments: ["cedar only"],
            primarySource: "M28"
        )
        assert(result: engine.recall(query: q44.query, memories: memories), satisfies: q44, ids: ids)

        let regularZara = memories.first { $0.id == ids["M12"] }!
        regularZara.isArchived = true
        let q49 = ManualRecallFixture.ValidationCase(
            "Q49",
            query: "What is my Zara regular T-shirt size?",
            expectedFragments: [
                "do not have your regular Zara T-shirt size saved",
                "loose-fit Zara T-shirt size",
                "may not be the same",
            ],
            primarySource: "M13"
        )
        assert(result: engine.recall(query: q49.query, memories: memories), satisfies: q49, ids: ids)

        let q50Result = engine.recall(query: "What did I save most recently?", memories: [])
        #expect(q50Result.citedMemoryIds.isEmpty)
        #expect(q50Result.text.localizedCaseInsensitiveContains("do not have any saved memories"))
    }

    @Test("Archived memories are excluded from recall and latest-memory fast path")
    @MainActor
    func archivedMemoriesExcludedFromRecall() {
        let archived = Self.makeMemory(
            "Mum wears size 38 shoes.",
            type: .fact,
            source: .text,
            createdAt: referenceDate.addingTimeInterval(60)
        )
        archived.isArchived = true
        let active = Self.makeMemory(
            "My blue suit size at Zara is 42.",
            type: .fact,
            source: .text,
            createdAt: referenceDate
        )

        let specific = RecallEngine().recall(
            query: "What size does mum wear?",
            memories: [archived, active]
        )
        #expect(specific.citedMemoryIds.isEmpty)

        let latest = RecallEngine().recall(
            query: "What did I save most recently?",
            memories: [archived, active]
        )
        #expect(latest.citedMemoryIds == [active.id])
        #expect(latest.text.localizedCaseInsensitiveContains("blue suit"))
    }

    @Test("Citation payloads match cited memory ids")
    @MainActor
    func citationPayloadsMatchCitedMemoryIds() {
        let memory = Self.makeMemory(
            "Ahmed prefers quiet restaurants.",
            type: .preference,
            source: .voice,
            createdAt: referenceDate
        )

        let result = RecallEngine().recall(
            query: "What does Ahmed prefer?",
            memories: [memory]
        )

        #expect(result.citations.map(\.id) == result.citedMemoryIds)
        #expect(result.citations.first?.summary == memory.summary)
        #expect(result.citations.first?.source == "Voice")
    }

    @Test("Recent memory query bypasses lexical scoring")
    @MainActor
    func recentMemoryFastPath() {
        let memories = Self.launchMemories(referenceDate: referenceDate)
        let result = RecallEngine().recall(query: "What did I save most recently?", memories: memories)
        let expectedMemory = memories[9]

        #expect(result.citedMemoryIds == [expectedMemory.id])
        #expect(result.text.localizedCaseInsensitiveContains("away from the lift"))
    }

    @Test("No matching memory fails gracefully without false citation")
    @MainActor
    func noMatch() {
        let memories = Self.launchMemories(referenceDate: referenceDate)
        let result = RecallEngine().recall(query: "What is my passport number?", memories: memories)

        #expect(result.citedMemoryIds.isEmpty)
        #expect(result.text.localizedCaseInsensitiveContains("could not find"))
    }

    @Test("Passport number query does not answer from passport location")
    @MainActor
    func passportNumberDoesNotUseLocationMemory() {
        let memory = Self.makeMemory(
            "My passport is in drawer 2 of the study desk.",
            type: .fact,
            source: .image,
            createdAt: referenceDate
        )

        let result = RecallEngine().recall(
            query: "What is my passport number?",
            memories: [memory]
        )

        #expect(result.text.localizedCaseInsensitiveContains("do not have a passport number saved"))
        #expect(!result.text.localizedCaseInsensitiveContains("drawer 2"))
        #expect(result.citedMemoryIds.isEmpty)
    }

    @Test("Birthday query requires the requested person and birthday in one memory")
    @MainActor
    func personBirthdayRequiresSamePersonEvidence() {
        let memories = [
            Self.makeMemory(
                "Ahmed prefers quiet restaurants.",
                type: .preference,
                source: .text,
                createdAt: referenceDate
            ),
            Self.makeMemory(
                "Nora's birthday gift idea is a Kindle case.",
                type: .fact,
                source: .voice,
                createdAt: referenceDate.addingTimeInterval(60)
            ),
        ]

        let result = RecallEngine().recall(
            query: "What is Ahmed's birthday?",
            memories: memories
        )

        #expect(result.text.localizedCaseInsensitiveContains("do not have Ahmed's birthday saved"))
        #expect(result.citedMemoryIds.isEmpty)
    }

    @Test("Home Wi-Fi query does not confidently answer with beach house password")
    @MainActor
    func homeWifiUsesCautiousBeachHouseCaveat() {
        let memory = Self.makeMemory(
            "The Wi-Fi password at the beach house is ReefSunset42.",
            type: .fact,
            source: .text,
            createdAt: referenceDate
        )

        let result = RecallEngine().recall(
            query: "What is the Wi-Fi password at home?",
            memories: [memory]
        )

        #expect(result.citedMemoryIds == [memory.id])
        #expect(result.text.localizedCaseInsensitiveContains("do not have a home Wi-Fi password saved"))
        #expect(result.text.localizedCaseInsensitiveContains("beach house"))
        #expect(result.text.localizedCaseInsensitiveContains("may be different"))
    }

    @Test("Regular size query returns caveat when only loose-fit size exists")
    @MainActor
    func regularSizeDoesNotCollapseToLooseFit() {
        let memory = Self.makeMemory(
            "My loose-fit T-shirt size at Zara is S.",
            type: .fact,
            source: .text,
            createdAt: referenceDate
        )

        let result = RecallEngine().recall(
            query: "What is my Zara regular T-shirt size?",
            memories: [memory]
        )

        #expect(result.citedMemoryIds == [memory.id])
        #expect(result.text.localizedCaseInsensitiveContains("do not have your regular Zara T-shirt size saved"))
        #expect(result.text.localizedCaseInsensitiveContains("loose-fit Zara T-shirt size"))
        #expect(result.text.localizedCaseInsensitiveContains("may not be the same"))
    }

    @Test("Person size query does not answer from unrelated size memories")
    @MainActor
    func personSizeQueryDoesNotUseUnrelatedSizeMemory() {
        let memories = [
            Self.makeMemory(
                "My size in Zara for t shirt is M and for blazer is S Loose Fit.",
                type: .fact,
                source: .text,
                createdAt: referenceDate
            ),
            Self.makeMemory(
                "size 39.",
                type: .fact,
                source: .text,
                createdAt: referenceDate.addingTimeInterval(60)
            ),
        ]

        let result = RecallEngine().recall(
            query: "What size does Tania wear now?",
            memories: memories
        )

        #expect(result.citedMemoryIds.isEmpty)
        #expect(result.text.localizedCaseInsensitiveContains("do not have Tania's size saved"))
    }

    @Test("Person size query still answers when that person's size exists")
    @MainActor
    func personSizeQueryUsesMatchingPersonMemory() {
        let memory = Self.makeMemory(
            "Tania wears size 41 shoes.",
            type: .fact,
            source: .text,
            createdAt: referenceDate
        )

        let result = RecallEngine().recall(
            query: "What size does Tania wear now?",
            memories: [memory]
        )

        #expect(result.citedMemoryIds == [memory.id])
        #expect(result.text.localizedCaseInsensitiveContains("41"))
    }

    @Test("Forget-to-buy query prioritises forgotten shopping memory")
    @MainActor
    func forgetToBuyIntentRanksForgottenItemFirst() {
        let dishwasher = Self.makeMemory(
            "I always forget to buy dishwasher tablets.",
            type: .list,
            source: .voice,
            createdAt: referenceDate
        )
        let candles = Self.makeMemory(
            "When buying candles, choose cedar or fig, not vanilla.",
            type: .preference,
            source: .voice,
            createdAt: referenceDate.addingTimeInterval(60)
        )

        let result = RecallEngine().recall(
            query: "What shopping thing do I keep forgetting?",
            memories: [dishwasher, candles]
        )

        #expect(result.citedMemoryIds.first == dishwasher.id)
        #expect(result.text.localizedCaseInsensitiveContains("dishwasher tablets"))
    }

    @Test("Parking query extracts the parking detail instead of broad venue")
    @MainActor
    func parkingQueryExtractsSpecificSpot() {
        let memory = Self.makeMemory(
            "The parking spot at Dubai Mall was P3, row C18.",
            type: .fact,
            source: .image,
            createdAt: referenceDate
        )

        let result = RecallEngine().recall(
            query: "Where did I park at Dubai Mall?",
            memories: [memory]
        )

        #expect(result.citedMemoryIds == [memory.id])
        #expect(result.text.localizedCaseInsensitiveContains("P3, row C18"))
        #expect(!result.text.localizedCaseInsensitiveContains("It was in Dubai Mall"))
    }

    private func assert(
        result: RecallResult,
        satisfies testCase: ManualRecallFixture.ValidationCase,
        ids: [String: UUID]
    ) {
        for fragment in testCase.expectedFragments {
            #expect(
                result.text.localizedCaseInsensitiveContains(fragment),
                "\(testCase.id) expected answer fragment: \(fragment). Actual: \(result.text)"
            )
        }

        if testCase.requiresNoCitations {
            #expect(result.citedMemoryIds.isEmpty, "\(testCase.id) expected no citations.")
            #expect(result.citations.isEmpty, "\(testCase.id) expected no citation payloads.")
        }

        if let primarySource = testCase.primarySource,
           let expectedId = ids[primarySource] {
            #expect(
                result.citedMemoryIds.first == expectedId,
                "\(testCase.id) expected first citation \(primarySource), got \(result.citedMemoryIds.first?.uuidString ?? "none")"
            )
        }

        #expect(result.citations.map(\.id) == result.citedMemoryIds)
    }

    @MainActor
    private static func launchMemories(referenceDate: Date) -> [MemoryRecord] {
        [
            makeMemory(
                "My blue suit size at Zara is 42.",
                type: .preference,
                source: .text,
                createdAt: referenceDate
            ),
            makeMemory(
                "Mum wears size 38 shoes.",
                type: .fact,
                source: .text,
                createdAt: referenceDate.addingTimeInterval(60)
            ),
            makeMemory(
                "I always forget to buy dishwasher tablets.",
                type: .list,
                source: .voice,
                createdAt: referenceDate.addingTimeInterval(120)
            ),
            makeMemory(
                "The Guam waterfall I liked was Tarzan Falls.",
                type: .preference,
                source: .image,
                createdAt: referenceDate.addingTimeInterval(180)
            ),
            makeMemory(
                "My dermatologist recommended La Roche-Posay Cicaplast.",
                type: .fact,
                source: .text,
                createdAt: referenceDate.addingTimeInterval(240)
            ),
            makeMemory(
                "For Gamma, I decided to cancel because I am travelling.",
                type: .fact,
                source: .text,
                createdAt: referenceDate.addingTimeInterval(300)
            ),
            makeMemory(
                "Ahmed prefers quiet restaurants.",
                type: .preference,
                source: .text,
                createdAt: referenceDate.addingTimeInterval(360)
            ),
            makeMemory(
                "The ACME forum winners need to be announced soon.",
                type: .fact,
                source: .text,
                createdAt: referenceDate.addingTimeInterval(420)
            ),
            makeMemory(
                "The board paper needs to be submitted in two weeks.",
                type: .fact,
                source: .text,
                createdAt: referenceDate.addingTimeInterval(480)
            ),
            makeMemory(
                "My preferred hotel room is away from the lift.",
                type: .preference,
                source: .text,
                createdAt: referenceDate.addingTimeInterval(540)
            ),
        ]
    }

    @MainActor
    private static func makeMemory(
        _ text: String,
        type: MemoryType,
        source: InputSource,
        createdAt: Date
    ) -> MemoryRecord {
        MemoryRecord(
            rawInput: text,
            summary: text,
            memoryType: type,
            persistenceScore: 0.80,
            inputSource: source,
            processingTier: .onDevice,
            modalityThresholdUsed: 0.90,
            confidence: 0.90,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}

struct RecallCase {
    let query: String
    let expectedText: String
    let expectedMemoryIndex: Int
}

let referenceDate = Date(timeIntervalSince1970: 1_783_296_000) // July 6, 2026 00:00:00 UTC

let recallCases: [RecallCase] = [
    RecallCase(
        query: "What size does mum wear?",
        expectedText: "38",
        expectedMemoryIndex: 1
    ),
    RecallCase(
        query: "What did I decide about Gamma?",
        expectedText: "cancel",
        expectedMemoryIndex: 5
    ),
    RecallCase(
        query: "Which waterfall did I like in Guam?",
        expectedText: "Tarzan Falls",
        expectedMemoryIndex: 3
    ),
    RecallCase(
        query: "What do I always forget to buy?",
        expectedText: "dishwasher tablets",
        expectedMemoryIndex: 2
    ),
    RecallCase(
        query: "Where was the waterfall?",
        expectedText: "Guam",
        expectedMemoryIndex: 3
    ),
    RecallCase(
        query: "When is the board paper due?",
        expectedText: "July 20, 2026",
        expectedMemoryIndex: 8
    ),
    RecallCase(
        query: "What does Ahmed prefer?",
        expectedText: "quiet restaurants",
        expectedMemoryIndex: 6
    ),
    RecallCase(
        query: "What hotel room do I prefer?",
        expectedText: "away from the lift",
        expectedMemoryIndex: 9
    ),
    RecallCase(
        query: "What skincare did the dermatologist recommend?",
        expectedText: "La Roche-Posay Cicaplast",
        expectedMemoryIndex: 4
    ),
]
