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
