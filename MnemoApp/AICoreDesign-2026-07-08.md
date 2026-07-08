# AI Core Design - 2026-07-08

## Product Direction
Mnemo should become an on-device AI-led private memory app. The AI layer should understand messy inputs, extract durable facts, retrieve semantically, and compose short source-grounded answers. The deterministic layer remains the safety system: storage truth, archive/delete rules, exact no-match guards, source-card citations, and fallback.

## Intended Pipeline

1. Capture
User saves text, voice transcript, or OCR text. The raw capture remains local.

2. Local extraction
A local model extracts:
- summary
- memory type
- subject
- entities
- dates
- locations
- tags
- confidence
- safety flags

3. Embedding
Generate real embeddings for:
- raw input
- summary
- entity-enriched text

4. Index
Store embeddings locally with:
- memory ID
- provider ID
- embedding version
- dimensions
- source modality
- created/updated timestamps

5. Retrieval
For a query:
- embed query locally
- retrieve candidate memories
- merge semantic and lexical candidates
- rerank with deterministic checks
- exclude archived/deleted memories
- preserve source IDs

6. Local answer composition
A local model produces a short answer using only the retrieved memories.

7. Citation validation
Before showing the answer:
- verify cited IDs are from retrieved memories
- reject unsupported claims
- reject factual answers with no citations
- fall back to cautious no-match or deterministic `RecallEngine` output when validation fails

8. UI
Show answer and source cards. Do not advertise AI Core while feature flags are off.

## Prototype Implementation In This Branch
- `AICoreFlags` defaults every AI path off and keeps deterministic fallback on.
- `AIRecallPipeline` exists beside `RecallEngine` and falls back to `RecallEngine`.
- `LocalAnswerComposer` parses the future JSON output contract.
- `AnswerCitationValidator` enforces citation safety before model answers can be trusted.

## Real vs Placeholder
- Real: deterministic recall, source citations, feature flags, answer JSON parser, citation validator tests.
- Placeholder: MLX model loading, Foundation Models generation, semantic embeddings, local answer generation.
- Not added: MLX dependency, model assets, model downloads, cloud LLM, UI claims.

## Recommended Next Sequence
1. Add an `EmbeddingProvider` protocol with deterministic provider as current default.
2. Add real embedding metadata and dimension checks to `VectorBridge`.
3. Prototype a small local embedding model behind `mlxEmbeddingsEnabled`.
4. Run retrieval quality tests before any answer-generation work.
5. Add local answer composition only after semantic retrieval and citation validation are stable.
