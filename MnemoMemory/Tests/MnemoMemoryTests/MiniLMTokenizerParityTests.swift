import Foundation
import Testing

@Suite("MiniLM tokenizer parity")
struct MiniLMTokenizerParityTests {

    @Test("MiniLM WordPiece tokenizer matches Hugging Face waterfall fixture")
    func waterfallTokenizationMatchesHuggingFaceFixture() throws {
        let fixture = try Self.loadFixture()
        let vocabURL = Self.fixtureDirectory.appendingPathComponent("minilm_vocab.txt")
        let tokenizer = try TestMiniLMWordPieceTokenizer(vocabURL: vocabURL)

        let output = tokenizer.tokenize(fixture.text)

        #expect(fixture.model == "sentence-transformers/paraphrase-MiniLM-L3-v2")
        #expect(fixture.note == "Tokenizer metadata only. No model weights or embeddings.")
        #expect(output.inputIDs == fixture.inputIDs)
        #expect(output.attentionMask == fixture.attentionMask)
        #expect(output.tokenTypeIDs == fixture.tokenTypeIDs)
        #expect(output.tokens == fixture.tokens)
    }

    private static var fixtureDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
    }

    private static func loadFixture() throws -> MiniLMTokenFixture {
        let fixtureURL = fixtureDirectory.appendingPathComponent("minilm_waterfall_tokens.json")
        let data = try Data(contentsOf: fixtureURL)
        return try JSONDecoder().decode(MiniLMTokenFixture.self, from: data)
    }
}

private struct MiniLMTokenFixture: Decodable {
    let text: String
    let model: String
    let inputIDs: [Int]
    let tokenTypeIDs: [Int]
    let attentionMask: [Int]
    let tokens: [String]
    let note: String

    enum CodingKeys: String, CodingKey {
        case text
        case model
        case inputIDs = "input_ids"
        case tokenTypeIDs = "token_type_ids"
        case attentionMask = "attention_mask"
        case tokens
        case note
    }
}

private struct TestMiniLMWordPieceTokenizer {
    private let tokenToID: [String: Int]
    private let unknownToken = "[UNK]"
    private let clsToken = "[CLS]"
    private let sepToken = "[SEP]"
    private let maxInputCharactersPerWord = 100

    init(vocabURL: URL) throws {
        let vocab = try String(contentsOf: vocabURL, encoding: .utf8)
        var tokenToID: [String: Int] = [:]
        for (index, token) in vocab.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let value = String(token).trimmingCharacters(in: .newlines)
            guard !value.isEmpty else { continue }
            tokenToID[value] = index
        }
        self.tokenToID = tokenToID
    }

    func tokenize(_ text: String) -> TestMiniLMTokenOutput {
        var tokens = [clsToken]
        for token in basicTokenize(text) {
            tokens.append(contentsOf: wordPieceTokenize(token))
        }
        tokens.append(sepToken)

        let inputIDs = tokens.map { tokenToID[$0] ?? tokenToID[unknownToken] ?? 100 }
        return TestMiniLMTokenOutput(
            inputIDs: inputIDs,
            tokenTypeIDs: Array(repeating: 0, count: inputIDs.count),
            attentionMask: Array(repeating: 1, count: inputIDs.count),
            tokens: tokens
        )
    }

    private func basicTokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""

        func flushCurrent() {
            guard !current.isEmpty else { return }
            tokens.append(current.lowercased())
            current = ""
        }

        for scalar in text.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                flushCurrent()
            } else if CharacterSet.punctuationCharacters.contains(scalar) {
                flushCurrent()
                tokens.append(String(scalar))
            } else {
                current.unicodeScalars.append(scalar)
            }
        }
        flushCurrent()
        return tokens
    }

    private func wordPieceTokenize(_ token: String) -> [String] {
        let characters = Array(token)
        guard characters.count <= maxInputCharactersPerWord else { return [unknownToken] }

        var subTokens: [String] = []
        var start = 0
        while start < characters.count {
            var end = characters.count
            var currentSubstring: String?

            while start < end {
                var substring = String(characters[start..<end])
                if start > 0 {
                    substring = "##" + substring
                }
                if tokenToID[substring] != nil {
                    currentSubstring = substring
                    break
                }
                end -= 1
            }

            guard let currentSubstring else {
                return [unknownToken]
            }

            subTokens.append(currentSubstring)
            start = end
        }
        return subTokens
    }
}

private struct TestMiniLMTokenOutput {
    let inputIDs: [Int]
    let tokenTypeIDs: [Int]
    let attentionMask: [Int]
    let tokens: [String]
}
