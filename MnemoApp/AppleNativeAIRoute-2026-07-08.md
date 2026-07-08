# Apple-Native AI Route - 2026-07-08

## Summary

Mnemo should pivot the next AI spike away from MiniLM-specific MLX embedding work and toward an Apple-native memory index first:

1. Keep deterministic recall as the default V1 path.
2. Add Core Spotlight memory indexing behind a feature flag.
3. Prove archive/delete/reset correctness against the Spotlight index.
4. Preserve Mnemo source identifiers so source cards remain trustworthy.
5. Only after retrieval and source hygiene are proven, evaluate Foundation Models answer composition.
6. Keep MLX runtime proof and provider boundaries as a fallback route for older OS/device paths, not the active next path.

This document uses Apple Developer resources only:

- Core Spotlight: `https://developer.apple.com/documentation/corespotlight`
- Adding app content to Spotlight indexes: `https://developer.apple.com/documentation/corespotlight/adding-your-app-s-content-to-spotlight-indexes`
- Searching for information in your app: `https://developer.apple.com/documentation/corespotlight/searching-for-information-in-your-app`
- `CSSearchableIndex`: `https://developer.apple.com/documentation/corespotlight/cssearchableindex`
- `CSSearchableItem`: `https://developer.apple.com/documentation/corespotlight/cssearchableitem`
- `CSSearchableItemAttributeSet`: `https://developer.apple.com/documentation/corespotlight/cssearchableitemattributeset`
- Foundation Models: `https://developer.apple.com/documentation/foundationmodels`
- `LanguageModelSession`: `https://developer.apple.com/documentation/foundationmodels/languagemodelsession`
- `Tool`: `https://developer.apple.com/documentation/foundationmodels/tool`
- Generating content and performing tasks with Foundation Models: `https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models`

## Core Spotlight Memory Indexing

Mnemo can donate each active memory to Core Spotlight as a `CSSearchableItem`.

Suggested mapping:

| Mnemo field | Core Spotlight role |
| --- | --- |
| `MemoryRecord.id` | `CSSearchableItem.uniqueIdentifier` |
| stable app namespace | `CSSearchableItem.domainIdentifier` |
| memory summary | `CSSearchableItemAttributeSet.title` or display title |
| searchable summary/raw text/tags | content fields on `CSSearchableItemAttributeSet` |
| source type | metadata field and/or keywords |
| created/updated date | date metadata |
| archive/delete state | not indexed when archived/deleted |

The identifier must be the same identifier Mnemo uses for source cards. Core Spotlight must never become a parallel identity system.

## Archive, Delete, and Reset Safety

Archived memories:

- remove the memory's `uniqueIdentifier` from the Spotlight index immediately,
- keep the memory in SwiftData,
- do not allow Chat retrieval from Spotlight to surface archived memories,
- re-index only if the user later unarchives the memory.

Permanently deleted memories:

- remove the memory's `uniqueIdentifier` from Core Spotlight,
- remove the SwiftData record,
- remove any vector/deterministic index rows,
- clear any stale chat citations that point at that source.

Delete All Data:

- delete all searchable items for Mnemo's domain identifier,
- wipe SwiftData memory state,
- wipe existing local vector/deterministic index state,
- reset App Lock and onboarding state as already defined by V1.

Failing to remove archived/deleted items is a trust-breaking bug because Spotlight-backed retrieval could cite memories that Mnemo says are hidden or gone.

## Source Identifiers and Source Cards

Source transparency remains Mnemo's product advantage.

Requirements:

- Every indexed Spotlight item must carry a stable source ID.
- The source ID must map back to a current, non-archived `MemoryRecord`.
- Any answer composed from Spotlight results must return cited source IDs.
- Before showing an answer, Mnemo must validate that every cited ID still exists and is active.
- Source cards should be rendered from Mnemo's database, not from Spotlight display snippets alone.

This keeps Core Spotlight as a retrieval layer, not the source of truth.

## Foundation Models Answer Composition

Foundation Models could later be used to compose short answers from retrieved memories through `LanguageModelSession` and tool calling.

Safe contract:

- answer only from retrieved memories,
- return cited memory IDs,
- say when no memory supports the answer,
- preserve conditions and qualifiers,
- avoid guessing sensitive facts,
- fail closed when citations are missing or unsupported.

Do not wire Foundation Models into Chat until retrieval, source-card mapping, archive/delete removal, and fail-closed behavior pass tests.

## SpotlightSearchTool and Local RAG

If the SDK exposes a `SpotlightSearchTool` suitable for app content, it could allow Foundation Models to query local Spotlight-indexed memories as a retrieval tool.

If that API is unavailable, unstable, or too broad for Mnemo's citation guarantees, Mnemo should implement a custom Foundation Models `Tool` that wraps app-controlled Core Spotlight queries and returns only:

- memory ID,
- summary,
- source type,
- created/updated date,
- a short snippet,
- no archived/deleted items.

The tool result should be structured. The model should not receive open-ended access to unrelated user/device Spotlight content.

## Citation and Fail-Closed Assessment

Core Spotlight can improve native retrieval, but it does not by itself guarantee citation correctness.

Mnemo's source attribution is strong enough only if Mnemo enforces all of these:

- app-owned domain identifiers,
- stable memory IDs,
- active-record validation after retrieval,
- model output requiring cited IDs,
- post-generation citation validation,
- no answer shown when cited IDs are missing, archived, deleted, or unsupported.

Fail-closed behavior is possible, but it is Mnemo's responsibility, not Foundation Models' responsibility alone.

## Privacy

Core Spotlight indexing is local platform indexing. It is a better fit for Mnemo than a server-backed embedding index because it keeps the next retrieval experiment inside Apple's local app/content search stack.

Privacy rules:

- no Private Cloud Compute in this V1 spike,
- no cloud LLM,
- no third-party provider,
- no account,
- no backend identity,
- no indexing of archived/deleted memories,
- no indexing before the feature flag is enabled,
- no user-facing claim that Foundation Models or Spotlight has been validated until it has.

Sensitive memories still need careful product treatment. Even local indexing can make content searchable in ways users may not expect, so the first implementation should be internal/DEBUG or clearly gated.

## OS and Device Availability Risks

Risks:

- Foundation Models availability depends on OS, device, region, language, Apple Intelligence availability, and SDK support.
- Core Spotlight is broadly native, but exact query APIs and ranking behavior vary by OS.
- Tool-calling and Spotlight integration details may differ between SDK releases.
- Physical-device validation is required before claiming real Apple Intelligence behavior.
- Simulator validation is not enough for device availability, privacy snapshots, and Apple Intelligence capability checks.

Availability gating must be explicit and fail closed to deterministic recall.

## TestFlight Risks

Core Spotlight indexing behind a feature flag is low-risk if disabled by default.

Risks if enabled too early:

- archived or deleted memories appearing in search results,
- source IDs not mapping cleanly back to Mnemo records,
- model answers without valid citations,
- OS/device feature availability confusion,
- App Review concern if copy overclaims local AI behavior.

The first TestFlight-safe stance should be:

- deterministic recall default,
- Apple-native indexing hidden behind internal flag,
- no Foundation Models Chat integration,
- no Private Cloud Compute,
- no new AI marketing claims.

## Why Apple-Native May Beat MiniLM for V1

Apple-native first is likely a better V1 path because:

- Core Spotlight already exists on device and is designed for app-content indexing.
- Archive/delete safety can be tested without model conversion.
- It avoids committing model assets.
- It avoids tokenizer/model parity maintenance.
- It reduces package and Metal shader build risk.
- It fits App Review and platform expectations better than bundling a custom embedding model before product behavior is proven.

MiniLM remains useful as a research fallback, but it is not the shortest path to a reliable V1 memory loop.

## Why MLX Remains

Keep MLX because:

- the runtime smoke passed on physical iPhone,
- the provider boundary is useful,
- older OS or non-Foundation-Models paths may need local embeddings later,
- MLX remains a credible fallback if Apple-native retrieval cannot satisfy Mnemo's source-card requirements.

Pause MiniLM-specific work because:

- model loading is unproven,
- weights are not bundled,
- MLXEmbedders/MLXNN route is not selected,
- citation behavior is a product risk best solved at retrieval/source level first.

## Decision Matrix

| Route | Privacy | Offline support | Citation control | Source-card compatibility | Engineering effort | OS dependency | Model quality | App Store risk | Retrieval quality | Hallucination risk | Archive/delete safety | TestFlight readiness |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Deterministic recall | Strong local-only | Strong | Strong | Strong | Low | Low | Limited | Low | Narrow but predictable | Low | Already testable | High |
| MLX MiniLM embeddings | Strong local-only if bundled | Strong after assets ship | Medium; needs validation | Medium; IDs must be preserved | High | Medium; MLX/device constraints | Potentially better semantic retrieval | Medium; asset/build risk | Better if model works | Medium without guardrails | Must be implemented | Low right now |
| Foundation Models + Core Spotlight RAG | Strong if local-only and no PCC | Depends on OS/device availability | Medium unless Mnemo validates IDs | Strong if source IDs survive | Medium | High | Potentially strong | Medium; availability/copy risk | Potentially strong native retrieval | Medium unless fail-closed | Must be proven | Medium after flag-gated indexing |
| Hybrid route | Strong with deterministic fallback | Strong fallback | Strong if Mnemo validates citations | Strong | Medium staged effort | Medium | Best long-term flexibility | Low-medium if claims are honest | Best staged path | Controlled by guardrails | Can be tested per layer | Best strategic path |

## Recommended Route

Hybrid, but Apple-native first:

1. Keep deterministic recall as default.
2. Add Core Spotlight memory indexing behind a feature flag.
3. Do not wire Foundation Models into Chat yet.
4. Do not use Private Cloud Compute.
5. Do not add third-party providers.
6. Use Apple-native RAG only after source-card, archive/delete, reset, and fail-closed behavior are proven.
7. Keep MLX runtime proof and provider boundary as fallback.
8. Pause MiniLM-specific model-loading work.

## Next Implementation Spike

Next task:

```text
Core Spotlight memory indexing behind a feature flag.
```

Not next:

- Foundation Models answer generation,
- Chat replacement,
- Private Cloud Compute,
- MLXEmbedders,
- MLXNN,
- MiniLM conversion.

Acceptance criteria for the next spike:

- feature flag default off,
- index one active memory into Core Spotlight,
- remove archived memory from the index,
- remove permanently deleted memory from the index,
- Delete All Data clears the app's Spotlight domain,
- source IDs map back to active `MemoryRecord` rows,
- no Chat path changes,
- deterministic recall remains default.
