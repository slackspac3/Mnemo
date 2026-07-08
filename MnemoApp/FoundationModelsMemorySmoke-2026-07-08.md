# Foundation Models Memory Smoke - 2026-07-08

## Summary

Mnemo now has a DEBUG-only Apple Foundation Models memory answer smoke.

This is the first local Apple Foundation Models runtime path in Mnemo. It is not production Chat integration, does not replace deterministic recall, and does not use Private Cloud Compute.

## Apple API Basis

The implementation was checked against the installed iOS 26.5 SDK and Apple Developer Foundation Models documentation:

- `FoundationModels`
- `SystemLanguageModel.default.availability`
- `LanguageModelSession`
- `LanguageModelSession.respond(to:options:)`
- `GenerationOptions`

The local SDK also exposes guided generation through `@Generable`, but this smoke intentionally uses a conservative JSON text contract plus post-generation validation so the output can fail closed without adding a model-backed UI path.

Apple Developer documentation:

- https://developer.apple.com/documentation/foundationmodels
- https://developer.apple.com/documentation/foundationmodels/languagemodelsession
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

## Launch Argument

```text
--run-foundation-models-memory-smoke
```

The smoke runs only in DEBUG builds and only when the launch argument is present.

## What The Smoke Does

1. Checks `SystemLanguageModel.default.availability`.
2. If unavailable, prints `available=false` and exits without crashing.
3. Creates one disposable memory:
   `I loved the waterfall in Guam.`
4. Indexes it through the existing Core Spotlight path with `coreSpotlightIndexingEnabled=true`.
5. Queries Core Spotlight for a unique smoke token attached to the memory.
6. Resolves the returned source ID through `MemorySourceCardResolver`.
7. Builds a constrained Foundation Models prompt using only the source-card-safe payload.
8. Asks: `Where was the waterfall I loved?`
9. Requires JSON output with:
   - `answer`
   - `sourceIdentifiers`
   - `insufficientEvidence`
10. Validates that:
   - an answer exists,
   - the answer contains `Guam`,
   - the cited source ID exactly matches the active memory,
   - the cited source resolves through `MemorySourceCardResolver`,
   - invalid or missing citations fail closed.
11. Deletes the seeded memory and clears the Mnemo Spotlight domain.

## Console Output Format

```text
Foundation Models memory smoke: available=<true|false> indexed=<true|false> queried=<true|false> sourceCardResolved=<true|false> modelAnswered=<true|false> citationsValid=<true|false> answer="<short answer or empty>" durationMs=<number> error="<none or message>"
```

## Simulator Result

Passed on iPhone 17 Pro simulator, iOS 26.5, through XcodeBuildMCP runtime logs.

```text
Foundation Models memory smoke: available=true indexed=true queried=true sourceCardResolved=true modelAnswered=true citationsValid=true answer="The waterfall you loved was in Guam." durationMs=3732.60 error="none"
```

This confirms:

- `SystemLanguageModel.default` was available in the simulator environment.
- The disposable memory was indexed and queried through Core Spotlight.
- The returned source ID resolved through `MemorySourceCardResolver`.
- Apple Foundation Models generated the answer.
- The cited source identifier matched the active `MemoryRecord`.
- Post-generation validation passed before the answer was considered usable.

## Physical iPhone Result

Pending.

Connected device seen by XcodeBuildMCP:

- Mr B
- iOS 26.6
- UDID `FFE5C4A6-31E5-580B-83D3-CD05172A8F2D`

Codex attempted a physical device run with `--run-foundation-models-memory-smoke`, but the build was blocked by local signing configuration:

```text
Signing for "Mnemo" requires a development team. Select a development team in the Signing & Capabilities editor. (in target 'Mnemo' from project 'Mnemo')
```

No signing, entitlement, project, or scheme changes were made or committed. Physical iPhone Foundation Models smoke validation remains pending until the app is run locally from Xcode with the launch argument.

## Runtime Behaviour

If Apple Foundation Models are unavailable because the device is not eligible, Apple Intelligence is disabled, or the model is not ready, the smoke reports the exact availability reason when the SDK exposes it.

The smoke does not fall back to:

- cloud LLM,
- Private Cloud Compute,
- third-party providers,
- MLX,
- deterministic answer composition pretending to be Foundation Models.

## Validation Contract

`SourceGroundedAnswerParser` and `SourceGroundedAnswerValidator` validate the model output without invoking Apple's model in unit tests.

The validator rejects:

- missing citations,
- malformed source IDs,
- citations outside the returned source set,
- `insufficientEvidence=true`,
- empty answers.

## Why Chat Recall Is Unchanged

This is a launch-argument-only runtime smoke. It is not wired into:

- `ChatView`,
- `ChatViewModel`,
- `RecallEngine`,
- Browse,
- source-card UI,
- production Settings.

Deterministic recall remains the default user-facing path.

## Why SpotlightSearchTool Is Not Used Yet

The current smoke manually queries Core Spotlight and validates the source ID before calling Foundation Models. `SpotlightSearchTool` should wait until the app has a tested custom tool contract, fail-closed behaviour, and user-facing privacy controls.

## Why Private Cloud Compute Is Not Used

This smoke uses `SystemLanguageModel.default` through the Foundation Models framework. No cloud endpoint or Private Cloud Compute route is configured or invoked by Mnemo.

## Remaining Risks

- Simulator/device Foundation Models availability may differ.
- The model may refuse, rate-limit, or report assets unavailable.
- JSON text output is conservative but less type-safe than guided generation.
- The answer contract is not yet wired to Chat or source cards.
- User controls and copy are required before any model-backed recall path can ship.

## Next Recommended Step

Run this smoke on the physical iPhone from Xcode with local signing and `--run-foundation-models-memory-smoke`, record exact output, then design the Foundation Models custom tool contract without wiring it into Chat.
