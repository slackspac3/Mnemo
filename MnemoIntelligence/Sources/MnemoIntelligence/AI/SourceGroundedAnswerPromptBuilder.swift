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
        Answer the question directly using the shortest relevant phrase from the cited memory.
        Extract the relevant fact from the memory instead of dumping the full memory text.
        Do not simply copy the full memory unless the full memory is the answer.
        You may omit irrelevant source words that do not answer the question.
        Do not dump full OCR or product-label text when a shorter supported product or name phrase answers the question.
        Preserve important product names, people, places, numbers, dates, and qualifiers.
        For names, brands, product names, model numbers, codes, locations, dates, sizes, and passwords, preserve the exact wording from the memory.
        If text looks OCR-noisy, answer with the clearest supported phrase from the memory.
        Do not invent corrections for OCR errors.
        Do not translate, normalize, autocorrect, replace, or improve OCR text with outside knowledge.
        If the memory says "GOURMET", do not answer "Gourmand".
        If a source contains label or noise words such as "produced", "made", "net weight", "ingredients", or OCR fragments that are not needed to answer the question, omit them.
        If the question asks for a favourite product, answer with the product or brand phrase, not the entire label text.
        If unsure which words are relevant, quote the shortest source phrase that directly answers the question.
        If a phrase looks awkward or OCR-like but is the only saved evidence, preserve it exactly or quote the relevant phrase.
        Natural phrasing is good, but exact relevant factual tokens are more important than style.
        Omission of irrelevant source words is allowed; invention or substitution is not.
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

        Source cards show the original capture. The answer should be a concise recall answer, not a raw OCR transcript.
        Do not repeat OCR noise unless it is part of the supported answer.
        The answer must not introduce unsupported wording.

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
