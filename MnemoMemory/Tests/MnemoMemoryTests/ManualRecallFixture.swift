import Foundation
@testable import MnemoMemory
import MnemoCore

enum ManualRecallFixture {
    static let referenceDate = Date(timeIntervalSince1970: 1_783_296_000) // July 6, 2026 00:00:00 UTC

    struct Seed {
        let key: String
        let text: String
        let type: MemoryType
        let source: InputSource
    }

    struct ValidationCase {
        let id: String
        let query: String
        let expectedFragments: [String]
        let primarySource: String?
        let requiresNoCitations: Bool

        init(
            _ id: String,
            query: String,
            expectedFragments: [String],
            primarySource: String? = nil,
            requiresNoCitations: Bool = false
        ) {
            self.id = id
            self.query = query
            self.expectedFragments = expectedFragments
            self.primarySource = primarySource
            self.requiresNoCitations = requiresNoCitations
        }
    }

    static let seeds: [Seed] = [
        Seed(key: "M01", text: "My blue suit size at Zara is 42.", type: .preference, source: .text),
        Seed(key: "M02", text: "Mum wears size 38 shoes.", type: .fact, source: .text),
        Seed(key: "M03", text: "I always forget to buy dishwasher tablets.", type: .list, source: .voice),
        Seed(key: "M04", text: "The Guam waterfall I liked was Tarzan Falls.", type: .preference, source: .image),
        Seed(key: "M05", text: "My dermatologist recommended La Roche-Posay Cicaplast.", type: .fact, source: .text),
        Seed(key: "M06", text: "For Gamma, I decided to cancel because I am travelling.", type: .fact, source: .text),
        Seed(key: "M07", text: "Ahmed prefers quiet restaurants.", type: .preference, source: .voice),
        Seed(key: "M08", text: "The ACME forum winners need to be announced soon.", type: .fact, source: .text),
        Seed(key: "M09", text: "The board paper needs to be submitted in two weeks.", type: .fact, source: .text),
        Seed(key: "M10", text: "My preferred hotel room is away from the lift.", type: .preference, source: .text),
        Seed(key: "M11", text: "My passport is in the top drawer of the study desk.", type: .fact, source: .image),
        Seed(key: "M12", text: "My regular T-shirt size at Zara is M.", type: .fact, source: .text),
        Seed(key: "M13", text: "My loose-fit T-shirt size at Zara is S.", type: .fact, source: .text),
        Seed(key: "M14", text: "Nora's birthday gift idea is a Kindle case.", type: .fact, source: .voice),
        Seed(key: "M15", text: "The Wi-Fi password at the beach house is ReefSunset42.", type: .fact, source: .text),
        Seed(key: "M16", text: "The parking spot at Dubai Mall was P3, row C18.", type: .fact, source: .image),
        Seed(key: "M17", text: "I liked the salmon starter at Orfali Bros.", type: .preference, source: .text),
        Seed(key: "M18", text: "Call the dentist after the insurance approval arrives.", type: .fact, source: .voice),
        Seed(key: "M19", text: "The invoice from BluePeak needs to be paid by Thursday.", type: .fact, source: .text),
        Seed(key: "M20", text: "I decided not to renew the trial for Notion AI.", type: .fact, source: .text),
        Seed(key: "M21", text: "The spare car key is in the black pouch.", type: .fact, source: .image),
        Seed(key: "M22", text: "Dad prefers aisle seats on long flights.", type: .preference, source: .text),
        Seed(key: "M23", text: "The plumber said the water pressure valve needs replacing.", type: .fact, source: .voice),
        Seed(key: "M24", text: "For the podcast launch, publish the teaser before the guest announcement.", type: .fact, source: .text),
        Seed(key: "M25", text: "My gym locker code is 2806.", type: .fact, source: .text),
        Seed(key: "M26", text: "The hotel breakfast I liked had shakshuka and strong coffee.", type: .preference, source: .image),
        Seed(key: "M27", text: "My tailor appointment is next Tuesday at 4 PM.", type: .fact, source: .text),
        Seed(key: "M28", text: "When buying candles, choose cedar or fig, not vanilla.", type: .preference, source: .voice),
        Seed(key: "M29", text: "Sarah said the workshop budget cap is 15,000 AED.", type: .fact, source: .text),
        Seed(key: "M30", text: "The backup hard drive is labelled Mnemo Archive.", type: .fact, source: .text),
    ]

    static let preMutationCases: [ValidationCase] = [
        ValidationCase("Q01", query: "What size does mum wear?", expectedFragments: ["38"], primarySource: "M02"),
        ValidationCase("Q02", query: "What did I decide about Gamma?", expectedFragments: ["cancel"], primarySource: "M06"),
        ValidationCase("Q03", query: "Which waterfall did I like in Guam?", expectedFragments: ["Tarzan Falls"], primarySource: "M04"),
        ValidationCase("Q04", query: "What do I always forget to buy?", expectedFragments: ["dishwasher tablets"], primarySource: "M03"),
        ValidationCase("Q05", query: "Where was the waterfall?", expectedFragments: ["Guam"], primarySource: "M04"),
        ValidationCase("Q06", query: "What did I save most recently?", expectedFragments: ["Mnemo Archive"], primarySource: "M30"),
        ValidationCase("Q07", query: "When is the board paper due?", expectedFragments: ["July 20, 2026"], primarySource: "M09"),
        ValidationCase("Q08", query: "What does Ahmed prefer?", expectedFragments: ["quiet restaurants"], primarySource: "M07"),
        ValidationCase("Q09", query: "What hotel room do I prefer?", expectedFragments: ["away from the lift"], primarySource: "M10"),
        ValidationCase("Q10", query: "What skincare did the dermatologist recommend?", expectedFragments: ["La Roche-Posay Cicaplast"], primarySource: "M05"),
        ValidationCase("Q11", query: "Where is my passport?", expectedFragments: ["top drawer"], primarySource: "M11"),
        ValidationCase("Q12", query: "What is my Zara regular T-shirt size?", expectedFragments: ["M"], primarySource: "M12"),
        ValidationCase("Q13", query: "What is my Zara loose-fit T-shirt size?", expectedFragments: ["S"], primarySource: "M13"),
        ValidationCase("Q14", query: "What gift idea did I save for Nora?", expectedFragments: ["Kindle case"], primarySource: "M14"),
        ValidationCase("Q15", query: "What is the beach house Wi-Fi password?", expectedFragments: ["ReefSunset42"], primarySource: "M15"),
        ValidationCase("Q16", query: "Where did I park at Dubai Mall?", expectedFragments: ["P3, row C18"], primarySource: "M16"),
        ValidationCase("Q17", query: "What did I like at Orfali Bros?", expectedFragments: ["salmon starter"], primarySource: "M17"),
        ValidationCase("Q18", query: "Who should I call after insurance approval?", expectedFragments: ["dentist"], primarySource: "M18"),
        ValidationCase("Q19", query: "When does the BluePeak invoice need paying?", expectedFragments: ["Thursday"], primarySource: "M19"),
        ValidationCase("Q20", query: "What trial did I decide not to renew?", expectedFragments: ["Notion AI"], primarySource: "M20"),
        ValidationCase("Q21", query: "Where is the spare car key?", expectedFragments: ["black pouch"], primarySource: "M21"),
        ValidationCase("Q22", query: "What seat does Dad prefer on long flights?", expectedFragments: ["aisle"], primarySource: "M22"),
        ValidationCase("Q23", query: "What did the plumber say needs replacing?", expectedFragments: ["water pressure valve"], primarySource: "M23"),
        ValidationCase("Q24", query: "What should happen before the podcast guest announcement?", expectedFragments: ["publish the teaser"], primarySource: "M24"),
        ValidationCase("Q25", query: "What is my gym locker code?", expectedFragments: ["2806"], primarySource: "M25"),
        ValidationCase("Q26", query: "What hotel breakfast did I like?", expectedFragments: ["shakshuka", "strong coffee"], primarySource: "M26"),
        ValidationCase("Q27", query: "When is my tailor appointment?", expectedFragments: ["next Tuesday", "4 PM"], primarySource: "M27"),
        ValidationCase("Q28", query: "What candle scent should I choose?", expectedFragments: ["cedar"], primarySource: "M28"),
        ValidationCase("Q29", query: "What is the workshop budget cap?", expectedFragments: ["15,000 AED"], primarySource: "M29"),
        ValidationCase("Q30", query: "What is the backup hard drive labelled?", expectedFragments: ["Mnemo Archive"], primarySource: "M30"),
        ValidationCase("Q31", query: "Where should I take Ahmed for dinner?", expectedFragments: ["quiet restaurants"], primarySource: "M07"),
        ValidationCase("Q32", query: "What shopping thing do I keep forgetting?", expectedFragments: ["dishwasher tablets"], primarySource: "M03"),
        ValidationCase("Q33", query: "Which skincare product was recommended?", expectedFragments: ["La Roche-Posay Cicaplast"], primarySource: "M05"),
        ValidationCase("Q34", query: "Did I renew Notion AI?", expectedFragments: ["not to renew"], primarySource: "M20"),
        ValidationCase("Q35", query: "What room should I ask for at a hotel?", expectedFragments: ["away from the lift"], primarySource: "M10"),
        ValidationCase("Q36", query: "What size is my blue suit?", expectedFragments: ["42"], primarySource: "M01"),
        ValidationCase("Q37", query: "What did Sarah say about the workshop?", expectedFragments: ["15,000 AED"], primarySource: "M29"),
        ValidationCase("Q38", query: "What needs to be announced soon?", expectedFragments: ["ACME forum winners"], primarySource: "M08"),
        ValidationCase("Q39", query: "What should I avoid when buying candles?", expectedFragments: ["vanilla"], primarySource: "M28"),
        ValidationCase("Q40", query: "What should I do for the podcast launch first?", expectedFragments: ["publish the teaser"], primarySource: "M24"),
        ValidationCase("Q45", query: "What is my passport number?", expectedFragments: ["do not have a passport number saved"], requiresNoCitations: true),
        ValidationCase("Q46", query: "What is Ahmed's birthday?", expectedFragments: ["do not have Ahmed's birthday saved"], requiresNoCitations: true),
        ValidationCase("Q47", query: "Where did I leave my sunglasses?", expectedFragments: ["could not find"], requiresNoCitations: true),
        ValidationCase("Q48", query: "What is the Wi-Fi password at home?", expectedFragments: ["do not have a home Wi-Fi password saved", "may be different"], primarySource: "M15"),
    ]

    static func makeMemories() -> [MemoryRecord] {
        seeds.enumerated().map { index, seed in
            MemoryRecord(
                id: uuid(index + 1),
                rawInput: seed.text,
                summary: seed.text,
                memoryType: seed.type,
                persistenceScore: 0.80,
                inputSource: seed.source,
                processingTier: .onDevice,
                modalityThresholdUsed: 0.90,
                confidence: 0.90,
                createdAt: referenceDate.addingTimeInterval(TimeInterval(index * 60)),
                updatedAt: referenceDate.addingTimeInterval(TimeInterval(index * 60))
            )
        }
    }

    static func idByKey(memories: [MemoryRecord]) -> [String: UUID] {
        Dictionary(uniqueKeysWithValues: zip(seeds.map(\.key), memories.map(\.id)))
    }

    static func uuid(_ index: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index))!
    }
}
