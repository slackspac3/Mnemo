# Local Answer Composer Plan - 2026-07-08

## Decision
Do not replace `RecallEngine` with a model. Add a local answer composer only after semantic retrieval is stable, and only as a source-grounded wording layer.

## Prompt Contract
The local model must receive:
- the user query
- a short list of retrieved memory snippets
- each snippet's memory ID
- explicit instructions to answer only from supplied memories

The model must:
- answer only from provided memories
- say when no memory supports the answer
- keep the answer short
- return cited memory IDs
- avoid guessing sensitive facts
- preserve user wording where possible
- never invent IDs

## Output Contract
```json
{
  "answer": "...",
  "citedMemoryIds": ["..."],
  "confidence": 0.0,
  "unsupportedClaims": []
}
```

## Validation Contract
Before UI display:
- JSON must parse.
- Confidence must be between `0.0` and `1.0`.
- Cited IDs must be a subset of retrieved candidate IDs.
- `unsupportedClaims` must be empty.
- Factual answers must cite at least one memory.
- Cautious no-match answers may have zero citations.

## Fallback Rules
Return deterministic `RecallEngine` output when:
- AI Core flags are disabled.
- Device/model capability is unavailable.
- Model output does not parse.
- Model cites unknown IDs.
- Model reports unsupported claims.
- Model returns an uncited factual answer.
- Model times out or memory pressure rises.

## Tests Added In This Branch
- `LocalAnswerComposer` parses valid JSON.
- malformed JSON is rejected.
- confidence outside `0...1` is rejected.
- citation validator rejects unsupported IDs.
- citation validator rejects uncited factual answers.
- citation validator permits cautious no-match without citations.

## What Is Not Implemented
- No local generative model is loaded.
- No MLX or Foundation Models answer generation is wired.
- No Chat UI copy changes advertise AI Core.
- No cloud LLM fallback is added.
