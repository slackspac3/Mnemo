import Foundation

public struct SourceGroundedPromptSource: Equatable, Sendable {
    public let alias: String
    public let source: String
    public let summary: String

    public init(alias: String, source: String, summary: String) {
        self.alias = alias
        self.source = source
        self.summary = summary
    }
}

public struct SourceGroundedAnswerPrompt: Equatable, Sendable {
    public let instructions: String
    public let prompt: String

    public init(instructions: String, prompt: String) {
        self.instructions = instructions
        self.prompt = prompt
    }
}

public struct SourceGroundedAnswerPromptBuilder: Sendable {
    public init() {}

    public func build(
        query: String,
        sources: [SourceGroundedPromptSource]
    ) -> SourceGroundedAnswerPrompt {
        let instructions = """
        You are Mnemo's local memory answerer.
        Answer only from the provided memories.
        Answer in one short natural sentence.
        Extract the relevant fact from the memory instead of dumping the full memory text.
        Do not simply copy the full memory unless the full memory is the answer.
        Preserve important product names, people, places, numbers, dates, and qualifiers.
        If text looks OCR-noisy, answer with the clearest supported phrase from the memory.
        Do not invent corrections for OCR errors.
        Do not use outside knowledge.
        Do not guess.
        Cite only the source aliases exactly as written, such as S1 or S2.
        Return exactly one JSON object and no Markdown.
        """
        let memoryBlock = sources.map { source in
            """
            Source \(source.alias):
            source: \(source.source)
            summary: \(source.summary)
            """
        }.joined(separator: "\n\n")
        let aliases = sources.map(\.alias).joined(separator: ", ")
        let prompt = """
        Memories:
        \(memoryBlock)

        Question: \(query)

        Return this JSON shape:
        {
          "answer": "short natural answer supported by the memories",
          "sourceIdentifiers": ["S1"],
          "insufficientEvidence": false
        }

        In this prompt, sourceIdentifiers means source aliases. Use only these aliases:
        \(aliases)

        Source cards show the original capture. The answer should be concise and should not repeat OCR noise unless it is part of the supported answer.

        If the memories do not support an answer, return:
        {
          "answer": "",
          "sourceIdentifiers": [],
          "insufficientEvidence": true
        }
        """

        return SourceGroundedAnswerPrompt(
            instructions: instructions,
            prompt: prompt
        )
    }
}
