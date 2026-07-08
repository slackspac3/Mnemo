# Local AI Chat Mode - 2026-07-08

## Summary

This pass adds a DEBUG-only Local AI Chat experiment. When enabled in AI Lab,
Chat first tries an on-device Apple Foundation Models answer grounded in saved
Mnemo memories. If the local AI path cannot return a validated, cited answer,
Chat falls back to the existing deterministic recall path.

Release builds remain unchanged.

## Enablement

Open Settings -> AI Lab in a DEBUG build and turn on:

`Local AI answers in Chat (DEBUG)`

The setting is stored under:

`mnemo.debugLocalAIChatEnabled`

The app target wraps this in `DebugAIChatSetting`. MnemoMemory uses the same raw
UserDefaults key inside DEBUG-only indexing code because the package cannot
depend on the app target.

## Pipeline

When the DEBUG toggle is on, `ChatViewModel.recall(query:context:)` first calls
`ChatAIRecallPipeline.attemptAnswer(query:context:)`.

The Local AI path:

1. Checks the DEBUG toggle.
2. Checks Apple Foundation Models availability.
3. Backfills the DEBUG Core Spotlight index with active, non-archived memories.
4. Queries Core Spotlight for source identifiers.
5. Resolves every returned identifier through `MemorySourceCardResolver`.
6. Builds a prompt using only SwiftData-backed memory summaries.
7. Requests strict JSON from Apple Foundation Models:
   `{ answer, sourceIdentifiers, insufficientEvidence }`
8. Parses with `SourceGroundedAnswerParser`.
9. Validates with `SourceGroundedAnswerValidator`.
10. Re-resolves cited source identifiers before returning a Chat-compatible answer.

The path returns `nil` for unavailable models, missing sources, invalid JSON,
missing citations, invalid citations, archived/deleted sources, or any other
failure. Chat then falls back to deterministic recall.

## DEBUG Indexing

Core Spotlight indexing for real memories is DEBUG-only in this pass.

When the toggle is turned on:

- `mnemo.debugLocalAIChatEnabled` is set to `true`.
- `MemoryCRUD.backfillSearchIndex(in:)` indexes active, non-archived memories.
- AI Lab shows progress and reports any DEBUG-only backfill error.

When the toggle is turned off:

- `mnemo.debugLocalAIChatEnabled` is set to `false`.
- `MemoryCRUD.resetSearchIndexItems()` clears Mnemo's Core Spotlight domain.
- SwiftData memories and VectorBridge rows are not deleted.

On DEBUG app launch, if the toggle is already on, `AppState` runs an idempotent
backfill. If the toggle is off, no launch backfill runs.

Capture-time indexing is centralized in `MemoryCRUD.insertAndIndex`: after a
memory is saved and vector-indexed, DEBUG builds check the shared UserDefaults
key and index only when Local AI Chat is enabled. Capture sheets do not know
about the setting.

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

## Foundation Models Unavailable

If Apple Foundation Models are unavailable because of OS, device eligibility,
Apple Intelligence state, or model readiness, Local AI Chat returns `nil` and
Chat uses deterministic recall.

## Manual Testing

1. Save a memory: `I loved the waterfall in Guam.`
2. Open Settings -> AI Lab.
3. Turn on `Local AI answers in Chat (DEBUG)`.
4. Ask in Chat: `Where was the waterfall I loved?`
5. Confirm the answer mentions Guam and shows a source card.
6. Tap the source card and confirm it opens the saved memory.
7. Turn the toggle off and confirm Mnemo's Spotlight domain is cleared.
8. Ask again and confirm deterministic recall still handles the query or fails safely.

AI Lab also includes a `Manual Local AI Chat Test` panel that calls the same
`ChatAIRecallPipeline` used by Chat.

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
