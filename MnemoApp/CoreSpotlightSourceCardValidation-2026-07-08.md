# Core Spotlight Source Card Validation - 2026-07-08

## Summary

Mnemo now has a small source-card validation layer for Core Spotlight-returned source identifiers. The resolver accepts a Spotlight-style source ID, validates it against SwiftData, and returns a source-card-safe payload only when the memory is still active.

This is not Chat integration. Chat recall remains deterministic and does not query Spotlight.

## What Was Implemented

- `MemorySourceCardPayload`
- `MemorySearchSourceCandidate`
- `MemorySourceCardResolver`

The resolver accepts either a raw `sourceIdentifier` string or a `MemorySearchSourceCandidate` that may contain Spotlight title/snippet fields.

## Why Spotlight Content Is Not Trusted

Core Spotlight is treated as a local identifier index, not as a trusted content source. Title, snippet, and description fields returned by Spotlight are ignored for source-card display.

The source-card payload is built only from the active `MemoryRecord` stored in Mnemo's SwiftData database.

## Source ID Mapping

Spotlight item identifiers use:

```text
MemoryRecord.id.uuidString
```

The resolver:

1. Parses the identifier as a UUID.
2. Fetches the matching `MemoryRecord`.
3. Rejects missing records.
4. Rejects archived records.
5. Builds a payload from the active record only.

## Active Record Behaviour

An active memory resolves to:

- memory UUID,
- source identifier string,
- memory summary,
- input source display label,
- memory type,
- created date,
- updated date.

This is enough for the existing source-card/detail flow to open the canonical `MemoryRecord` rather than relying on Spotlight snippets.

## Archived, Deleted And Malformed Behaviour

| Input | Behaviour |
| --- | --- |
| Malformed UUID | Fails closed with `nil`. |
| Missing UUID | Fails closed with `nil`. |
| Archived memory | Fails closed with `nil`. |
| Permanently deleted memory | Fails closed with `nil`. |
| Misleading Spotlight title/snippet | Ignored; payload uses SwiftData memory content. |

## DEBUG Smoke Output

The Core Spotlight query smoke now includes `sourceCardResolved`.

Current smoke launch argument remains:

```text
--run-core-spotlight-query-smoke
```

Updated output format:

```text
Core Spotlight query smoke: indexed=<true|false> queried=<true|false> found=<true|false> sourceValidated=<true|false> sourceCardResolved=<true|false> archivedRejected=<true|false> deletedRejected=<true|false> cleared=<true|false> durationMs=<number> error="<none or message>"
```

`sourceCardResolved=true` proves that a real Core Spotlight query result identifier was converted into a `MemorySourceCardPayload` by rehydrating the active `MemoryRecord` from SwiftData. The smoke also passes untrusted Spotlight title/snippet values and verifies the payload summary still comes from SwiftData.

Simulator result, iPhone 17 Pro simulator on iOS 26.5:

```text
Core Spotlight query smoke: indexed=true queried=true found=true sourceValidated=true sourceCardResolved=true archivedRejected=true deletedRejected=true cleared=true durationMs=4132.39 error="none"
```

The earlier simulator and physical iPhone smoke results remain valid for the old format. Physical iPhone validation is still pending for the new `sourceCardResolved` format.

## Why Chat Recall Is Unchanged

The resolver is a trust-layer spike. It is not wired into `ChatView`, `ChatViewModel`, `RecallEngine`, Browse, source-card UI, or VectorBridge retrieval.

## Why Foundation Models And SpotlightSearchTool Remain Out Of Scope

Foundation Models and `SpotlightSearchTool` should not be wired until the app has proven:

- source ID validation,
- archive/delete rejection,
- source-card payload safety,
- fail-closed behaviour,
- user-facing privacy controls.

This pass addresses only source ID validation and payload safety.

## Remaining Risks

- The resolver is package-tested but not wired into a user flow.
- The resolver has simulator smoke coverage after a real Core Spotlight query.
- A physical iPhone smoke pass is still needed for the new `sourceCardResolved` output format.
- User-facing controls are still required before Core Spotlight indexing is enabled outside internal builds.

## Next Recommended Spike

Rerun the updated source-card resolver smoke on physical iPhone, then design the Foundation Models custom tool contract without wiring it into Chat.
