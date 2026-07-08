# Core Spotlight Query Smoke - 2026-07-08

## Summary

Mnemo now has a DEBUG-only Core Spotlight query smoke path. It proves the indexing layer can move from a local `MemoryRecord` to a Core Spotlight query result and then back to an active SwiftData source ID before anything is trusted.

The smoke now also resolves that source identifier into a source-card-safe payload with `MemorySourceCardResolver`.

This does not change Chat recall. Deterministic recall remains the default path.

## Launch Argument

```text
--run-core-spotlight-query-smoke
```

The smoke runs only in DEBUG builds and only when the launch argument is present.

## What The Smoke Does

1. Creates one disposable memory with a unique token:
   `Core Spotlight smoke memory waterfall guam private recall <unique-token>.`
2. Inserts the memory through `MemoryCRUD.insertAndIndex` with `coreSpotlightIndexingEnabled=true`.
3. Queries Core Spotlight for the unique token.
4. Treats the Spotlight result only as a source identifier.
5. Validates that identifier against an active `MemoryRecord` in SwiftData.
6. Resolves the identifier into a `MemorySourceCardPayload` from SwiftData only.
7. Confirms the payload ID, source identifier, and summary match the seeded `MemoryRecord`.
8. Confirms untrusted Spotlight title/snippet fields are not used for the payload.
9. Archives the memory and confirms the result is removed and rejected by active-record/source-card validation.
10. Permanently deletes the memory and confirms the result is removed and rejected.
11. Calls `MemoryCRUD.resetSearchIndexItems` to clear the Mnemo Spotlight domain.
12. Cleans up its own SwiftData/vector/search artefacts.

## Console Output Format

```text
Core Spotlight query smoke: indexed=<true|false> queried=<true|false> found=<true|false> sourceValidated=<true|false> sourceCardResolved=<true|false> archivedRejected=<true|false> deletedRejected=<true|false> cleared=<true|false> durationMs=<number> error="<none or message>"
```

## Simulator Result

Simulator smoke was run on an iPhone 17 Pro simulator, iOS 26.5, through XcodeBuildMCP with the launch argument above.

Observed console output:

```text
Core Spotlight query smoke: indexed=true queried=true found=true sourceValidated=true sourceCardResolved=true archivedRejected=true deletedRejected=true cleared=true durationMs=4132.39 error="none"
```

This supersedes the earlier simulator output format by adding `sourceCardResolved=true`. The previous simulator pass is not invalidated; it covered the same indexing/query lifecycle before the source-card resolver check existed.

## Physical iPhone Result

Physical iPhone validation passed for the updated `sourceCardResolved` smoke format on:

- Device: `Mr B`
- OS: iOS 26.6
- UDID: `FFE5C4A6-31E5-580B-83D3-CD05172A8F2D`

The smoke was run from Xcode with:

```text
--run-core-spotlight-query-smoke
```

Captured Xcode console output:

```text
Core Spotlight query smoke: indexed=true queried=true found=true sourceValidated=true sourceCardResolved=true archivedRejected=true deletedRejected=true cleared=true durationMs=295.06 error="none"
```

All updated smoke checks passed on device:

- `indexed=true`
- `queried=true`
- `found=true`
- `sourceValidated=true`
- `sourceCardResolved=true`
- `archivedRejected=true`
- `deletedRejected=true`
- `cleared=true`
- `error="none"`

This was captured from the Xcode console. The previous physical iPhone smoke output for the older format is superseded, not invalidated.

The smoke harness archives, permanently deletes, and clears its own test artefact. No seeded memory or Spotlight item was intentionally left behind.

## Delete All Data Semantics

Delete All Data now calls `MemoryCRUD.resetSearchIndexItems()`, which always clears the Mnemo Spotlight domain. Normal lifecycle indexing and removal remain behind `coreSpotlightIndexingEnabled`, but reset/privacy deletion must be reliable even if an internal flag was previously enabled and is now off.

This cleanup is safe if no items were indexed.

## Archive/Delete Rejection

Spotlight query results are never trusted directly. Result identifiers must map back to an active `MemoryRecord`. Archived and missing records are rejected by `MemorySearchIndexingService.activeRecord(forSourceIdentifier:in:)` and by `MemorySourceCardResolver`.

## Why Chat Recall Is Unchanged

Core Spotlight query results are not wired into Chat, Browse, source cards, VectorBridge, or RecallEngine. The smoke exists to validate indexing/query lifecycle behaviour and source-card-safe payload resolution only.

## Why Foundation Models Is Not Wired

Foundation Models and `SpotlightSearchTool` need source-card validation, archive/delete safety, and fail-closed query behaviour before they can be considered. This pass proves only the local indexing and identifier validation foundation.

## Remaining Risks

- Real Core Spotlight query latency and consistency have one simulator pass and one physical iPhone pass for the updated `sourceCardResolved` format.
- User-facing settings and copy are required before enabling indexing outside internal builds.
- The query syntax may need refinement after real-world search smoke data.
- The system search privacy posture must be reviewed before release exposure.

## Next Recommended Spike

Design the Foundation Models custom tool contract without wiring it into Chat.
