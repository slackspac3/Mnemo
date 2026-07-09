# Local AI Chat Mode - 2026-07-08

## Summary

This pass adds a DEBUG-only Local AI Chat path. In DEBUG builds, Chat first
tries an on-device Apple Foundation Models answer grounded in saved Mnemo
memories. If the local AI path cannot return a validated, cited answer, Chat
falls back to the existing deterministic recall path.

Release builds remain unchanged.

## Chat Routing

Local AI is the primary Chat path by default in DEBUG builds. AI Lab keeps a
temporary fallback-only override for comparison:

`Use Local AI first in Chat (DEBUG)`

Turning that switch off stores:

`mnemo.debugDeterministicChatOnly = true`

The app target wraps this in `DebugAIChatSetting`. MnemoMemory reads the same
raw deterministic-only key inside DEBUG-only indexing code because the package
cannot depend on the app target.

## Pipeline

In DEBUG builds, `ChatViewModel.recall(query:context:)` first calls
`ChatAIRecallPipeline.attemptAnswer(query:context:)` unless the deterministic
fallback-only override is enabled.

The Local AI path:

1. Checks the DEBUG fallback-only override.
2. Checks Apple Foundation Models availability.
3. Backfills the DEBUG Core Spotlight index with active, non-archived memories.
4. Queries Core Spotlight for source identifiers.
5. Resolves every returned identifier through `MemorySourceCardResolver`.
6. Assigns model-facing aliases to resolved sources: `S1`, `S2`, `S3`.
7. Builds a prompt using only SwiftData-backed memory summaries and aliases.
8. Requests strict JSON from Apple Foundation Models:
   `{ answer, sourceIdentifiers, insufficientEvidence }`
9. Treats model `sourceIdentifiers` as aliases, not app UUIDs.
10. Maps aliases back to MemoryRecord UUID source identifiers.
11. Validates the UUID-mapped output with `SourceGroundedAnswerValidator`.
12. Re-resolves cited source identifiers before returning a Chat-compatible answer.

The path returns `nil` for unavailable models, missing sources, invalid JSON,
missing citations, invalid citations, archived/deleted sources, or any other
failure. Chat then falls back to deterministic recall.

## DEBUG Indexing

Core Spotlight indexing for real memories is DEBUG-only in this pass.

When DEBUG Local AI-first Chat is active:

- `MemoryCRUD.backfillSearchIndex(in:)` indexes active, non-archived memories.
- AI Lab shows progress and reports any DEBUG-only backfill error.

When the AI Lab switch is turned off:

- `mnemo.debugDeterministicChatOnly` is set to `true`.
- Chat skips Local AI and uses deterministic recall only.
- `MemoryCRUD.resetSearchIndexItems()` clears Mnemo's DEBUG Core Spotlight
  domain.
- SwiftData memories and VectorBridge rows are not deleted.

On DEBUG app launch, `AppState` runs an idempotent backfill unless the
deterministic-only override is enabled.

Capture-time indexing is centralized in `MemoryCRUD.insertAndIndex`: after a
memory is saved and vector-indexed, DEBUG builds check the shared
deterministic-only UserDefaults key and index when Local AI-first Chat is
active. Capture sheets do not know about the setting.

## Release Privacy Boundary

Release indexing is not enabled.

Core Spotlight is a system-level index. Even though it is local and on-device,
indexed memory summaries may be discoverable through system Spotlight outside
Mnemo's App Lock UI. A production version needs explicit product and privacy
controls before Mnemo memories are donated to system Spotlight.

## Spotlight Latency

Immediately after a fresh capture or DEBUG backfill, Spotlight may briefly
return no candidates even though indexing succeeded. The Local AI Chat path
queries with bounded retries: up to three attempts with about 200 ms between
attempts. If no source IDs are available, it falls back to deterministic recall.

## Source Cards

Source cards remain grounded in SwiftData. Spotlight title and snippet content
are not trusted for display. Returned source IDs are rehydrated through
`MemorySourceCardResolver`, and the Chat response carries the resolved memory
IDs and summaries into the existing source-card UI.

Foundation Models does not see raw MemoryRecord UUIDs for citation copying. The
prompt exposes short aliases such as `S1` and `S2`. After parsing, Mnemo maps
those aliases back to UUID source identifiers and then runs the existing
`SourceGroundedAnswerValidator`. This keeps the final app citation contract
strict while avoiding brittle UUID copying by the model.

## Answer Style Tuning

Local AI Chat asks Foundation Models to answer in a short natural sentence,
extract the relevant fact, and avoid dumping the full memory unless the full
memory is itself the answer. Product names, people, places, numbers, dates, and
qualifiers should be preserved.

OCR-noisy text should not be corrected with outside knowledge. The model should
use the clearest supported phrase from the saved memory and cite the source
alias. Source cards remain the place to inspect the original capture and any raw
OCR text.

Grounding and citation validation are unchanged: aliases are mapped back to UUID
source identifiers, `SourceGroundedAnswerValidator` still runs on UUIDs, and the
source-card payload is still rehydrated from SwiftData.

## Answer Extraction vs. Fidelity

The answer can omit irrelevant OCR or source-label words when they do not answer
the question. For example, if a butter label memory contains `PRODUCED RANCE`
before the product name, Local AI may omit `PRODUCED RANCE` when answering
`What's my favourite butter?`.

Omission is not the same as substitution. Local AI must preserve exact supported
tokens for names, product names, codes, numbers, dates, places, and sizes.
`GOURMET` cannot become `Gourmand`, and OCR text must not be translated,
normalised, autocorrected, or improved with outside knowledge.

The model-facing prompt now asks for the shortest relevant phrase from the cited
memory rather than a raw OCR transcript. If the model introduces unsupported
significant tokens, the fidelity guard rejects the answer and Chat falls back to
deterministic recall. Source cards remain the raw source of truth.

## Answer Fidelity Guard

The butter device test exposed a second Local AI trust issue: the saved memory
said `GOURMET BUTTER`, but the model answered with `Gourmand Unsalted Butter`.
That kind of translation, normalisation, or embellishment is not acceptable for
memory recall.

The prompt now tells Foundation Models to copy exact wording for names, brands,
product names, model numbers, codes, locations, dates, sizes, and passwords. If
the memory says `GOURMET`, the model must not answer `Gourmand`. Natural phrasing
is allowed, but exact factual tokens are more important.

After UUID citation validation and source-card re-resolution, Local AI Chat runs
`SourceGroundedAnswerFidelityValidator` against the cited SwiftData summaries.
The validator ignores common helper words, but rejects significant answer tokens
that are absent from both the user question and cited summaries. If fidelity
validation fails, `ChatAIRecallPipeline` returns `nil` and Chat falls back to
deterministic recall. AI Lab shows the fidelity failure reason, for example
`Unsupported answer token: gourmand`.

Source cards remain the raw source of truth for inspecting OCR text and original
captures.

## Foundation Models Unavailable

If Apple Foundation Models are unavailable because of OS, device eligibility,
Apple Intelligence state, or model readiness, Local AI Chat returns `nil` and
Chat uses deterministic recall.

## Manual Testing

1. Save a memory: `I loved the waterfall in Guam.`
2. Ask in Chat: `Where was the waterfall I loved?`
3. Confirm the answer mentions Guam and shows a source card.
4. Tap the source card and confirm it opens the saved memory.
5. Open Settings -> AI Lab.
6. Turn off `Use Local AI first in Chat (DEBUG)`.
7. Ask again and confirm deterministic recall still handles the query or fails safely.

AI Lab also includes a `Manual Local AI Chat Test` panel that calls the same
`ChatAIRecallPipeline` used by Chat, even when the fallback-only override is on.
The manual path backfills the DEBUG search index before querying.

## Troubleshooting

Error:

`Model returned malformed source identifiers.`

Meaning:

The old UUID-copying path or UUID validator rejected source IDs copied by the
model.

Expected after this alias fix:

The model cites aliases such as `S1`, then Mnemo maps those aliases back to
UUIDs before validation. AI Lab now shows retrieved source count, resolved source
count, raw model aliases, mapped UUIDs, raw model answer, and validation error so
future failures identify whether retrieval, source resolution, alias mapping, or
UUID validation failed.

## Non-Goals

- No Release Local AI Chat.
- No Release Core Spotlight memory indexing.
- No Chat replacement in production.
- No SpotlightSearchTool.
- No Private Cloud Compute.
- No cloud LLM.
- No backend or auth.
- No StoreKit or monetisation.
- No MLXNN, MLXEmbedders, MiniLM, or bundled model weights.
- No user-facing AI claims.

## Remaining Risks

- Core Spotlight retrieval quality is still a prototype and uses simple query
  variants.
- Foundation Models output is validated, but not yet tuned for broader memory
  types.
- Production consent, privacy copy, and Spotlight visibility controls are not
  designed yet.
- Physical-device testing is still required for realistic latency and model
  availability across devices.

## Next Step

Run focused physical-device QA of DEBUG Local AI Chat with real saved memories,
especially source-card tap-through, archived/deleted source rejection, and
fallback behaviour when Foundation Models is unavailable or no cited answer can
be validated.
