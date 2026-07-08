# Core Spotlight Query Smoke - 2026-07-08

## Summary

Mnemo now has a DEBUG-only Core Spotlight query smoke path. It proves the indexing layer can move from a local `MemoryRecord` to a Core Spotlight query result and then back to an active SwiftData source ID before anything is trusted.

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
6. Archives the memory and confirms the result is removed or rejected by active-record validation.
7. Permanently deletes the memory and confirms the result is removed or rejected.
8. Calls `MemoryCRUD.resetSearchIndexItems` to clear the Mnemo Spotlight domain.
9. Cleans up its own SwiftData/vector/search artefacts.

## Console Output Format

```text
Core Spotlight query smoke: indexed=<true|false> queried=<true|false> found=<true|false> sourceValidated=<true|false> archivedRejected=<true|false> deletedRejected=<true|false> cleared=<true|false> durationMs=<number> error="<none or message>"
```

Simulator smoke was run on an iPhone 17 Pro simulator through XcodeBuildMCP with the launch argument above.

Observed console output:

```text
Core Spotlight query smoke: indexed=true queried=true found=true sourceValidated=true archivedRejected=true deletedRejected=true cleared=true durationMs=6848.48 error="none"
```

## Physical iPhone Result

Physical iPhone validation passed on:

- Device: `Mr B`
- OS: iOS 26.6
- UDID: `FFE5C4A6-31E5-580B-83D3-CD05172A8F2D`

The smoke was run from Xcode with:

```text
--run-core-spotlight-query-smoke
```

Captured Xcode console output:

```text
Core Spotlight query smoke: indexed=true queried=true found=true sourceValidated=true archivedRejected=true deletedRejected=true cleared=true durationMs=324.23 error="none"
Type: stdio
```

All smoke checks passed on device:

- `indexed=true`
- `queried=true`
- `found=true`
- `sourceValidated=true`
- `archivedRejected=true`
- `deletedRejected=true`
- `cleared=true`
- `error="none"`

The smoke harness archives, permanently deletes, and clears its own test artefact. No seeded memory or Spotlight item was intentionally left behind.

## Delete All Data Semantics

Delete All Data now calls `MemoryCRUD.resetSearchIndexItems()`, which always clears the Mnemo Spotlight domain. Normal lifecycle indexing and removal remain behind `coreSpotlightIndexingEnabled`, but reset/privacy deletion must be reliable even if an internal flag was previously enabled and is now off.

This cleanup is safe if no items were indexed.

## Archive/Delete Rejection

Spotlight query results are never trusted directly. Result identifiers must map back to an active `MemoryRecord`. Archived and missing records are rejected by `MemorySearchIndexingService.activeRecord(forSourceIdentifier:in:)`.

## Why Chat Recall Is Unchanged

Core Spotlight query results are not wired into Chat, Browse, source cards, VectorBridge, or RecallEngine. The smoke exists to validate indexing/query lifecycle behaviour only.

## Why Foundation Models Is Not Wired

Foundation Models and `SpotlightSearchTool` need source-card validation, archive/delete safety, and fail-closed query behaviour before they can be considered. This pass proves only the local indexing and identifier validation foundation.

## Remaining Risks

- Real Core Spotlight query latency and consistency have one simulator pass and one physical iPhone pass.
- User-facing settings and copy are required before enabling indexing outside internal builds.
- The query syntax may need refinement after real-world search smoke data.
- The system search privacy posture must be reviewed before release exposure.

## Next Recommended Spike

Design the next Apple-native spike around source-card validation for Spotlight-returned IDs before any Foundation Models or `SpotlightSearchTool` work.
