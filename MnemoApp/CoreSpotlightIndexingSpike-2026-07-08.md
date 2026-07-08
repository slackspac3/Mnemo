# Core Spotlight Indexing Spike - 2026-07-08

## Summary

Mnemo now has a small Core Spotlight indexing layer behind a disabled-by-default feature flag. The implementation indexes active memories, removes archived or permanently deleted memories, clears Mnemo Spotlight items during Delete All Data, and preserves the Mnemo memory UUID as the Spotlight item identifier.

This is indexing only. Chat recall, source cards, Browse search, VectorBridge indexing, and deterministic RecallEngine behaviour are unchanged.

## Feature Flag

| Flag | Default | Scope | Notes |
| --- | --- | --- | --- |
| `coreSpotlightIndexingEnabled` | `false` | `MemorySearchIndexingFlags` | Existing app paths use the disabled default. Tests can opt in with `.debugCoreSpotlight`. |

The flag lives in `MnemoMemory` rather than `MnemoIntelligence` so memory lifecycle operations can make indexing decisions without creating a package dependency cycle.

## Indexed Fields

| Field | Source | Purpose |
| --- | --- | --- |
| `uniqueIdentifier` | `MemoryRecord.id.uuidString` | Stable source ID for round-tripping back to SwiftData. |
| `domainIdentifier` | `com.thinkact.mnemo.memories` | Allows clearing only Mnemo memory items. |
| `title` | `MemoryRecord.summary` | Searchable display title. |
| `contentDescription` | `MemoryRecord.summary` | Searchable content text. |
| `keywords` | Memory type, input source, tags, UUID | Lightweight metadata for future query tests. |

The first spike indexes the memory summary and metadata only. Source cards must still render from the Mnemo database, not from Spotlight snippets.

## Lifecycle Behaviour

| Lifecycle point | Behaviour when flag is on | Behaviour when flag is off |
| --- | --- | --- |
| Active memory create/save | Indexes a `CSSearchableItem` for non-archived memory. | No-op. |
| Archived memory | Removes the memory UUID from Spotlight. | No-op. |
| Permanently deleted memory | Removes the memory UUID from Spotlight. | No-op. |
| Missing deleted memory ID | Removes the orphaned UUID from Spotlight if requested. | No-op. |
| Delete All Data | Always removes all items in `com.thinkact.mnemo.memories`, regardless of the indexing flag. | Always removes all items in `com.thinkact.mnemo.memories`. |
| Unarchive | Not currently wired because V1 has no exposed unarchive flow. Future unarchive should re-index the active record. | No-op. |

## Source ID Strategy

Core Spotlight identifiers are the exact `MemoryRecord.id.uuidString`. A result identifier can be validated by fetching the matching `MemoryRecord` and rejecting missing or archived records. This keeps source cards grounded in the local store and prevents archived/deleted Spotlight results from becoming trusted sources.

## Availability Handling

`CoreSpotlightMemoryIndexer` compiles behind `#if canImport(CoreSpotlight)`. Platforms without Core Spotlight receive a no-op implementation. The lifecycle service is also flag-gated, so current V1 behaviour remains deterministic even on supported platforms.

## Privacy Notes

Core Spotlight indexing is local to the device, but indexed text can be surfaced by system search. For this reason the feature is off by default and should remain internal until users have explicit, honest controls. This spike indexes only fields Mnemo already stores locally for recall, but product copy and settings controls are required before enabling this broadly.

Delete All Data clears Mnemo's Spotlight domain even when indexing is disabled. This is intentional: reset/privacy deletion should clean up any previous internal indexing state even if the normal feature flag is currently off.

## Why Chat Recall Is Unchanged

The goal is to prove lifecycle-safe indexing before retrieval. Mnemo does not query Spotlight from Chat in this pass, does not use `SpotlightSearchTool`, and does not replace VectorBridge or deterministic RecallEngine behaviour.

## Why Foundation Models Is Not Wired

Foundation Models answer composition depends on reliable source retrieval, archive/delete safety, citation validation, and fail-closed behaviour. This pass only establishes the indexing lifecycle. Answer generation remains out of scope.

## Tests Added

The new `MemorySearchIndexingTests` use a fake indexer to validate lifecycle decisions without depending on Core Spotlight availability:

- feature flag defaults off,
- active memories index only when enabled,
- archived memories are not indexed,
- archive removes the memory ID,
- permanent delete removes the memory ID,
- missing delete removes orphaned IDs,
- Delete All Data calls `removeAll` only when enabled,
- source IDs survive payload creation,
- source ID validation rejects missing or archived records,
- deterministic recall remains independent of search indexing.

## Remaining Risks

- Real Core Spotlight query behaviour is not validated yet.
- System search visibility needs product and privacy controls before release.
- Device-level indexing latency and failure modes are not measured.
- No UI exists to enable or explain Spotlight indexing.
- Source-card validation after a real Spotlight query is still pending.

## Next Recommended Spike

Core Spotlight DEBUG query smoke with one seeded memory.

That spike should remain behind the same flag and prove that a locally indexed memory can be queried, mapped back to an active `MemoryRecord`, and rejected after archive/delete. It should not add Foundation Models, Chat replacement, or user-facing AI claims.
