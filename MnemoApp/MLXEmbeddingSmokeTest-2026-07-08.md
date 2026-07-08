# MLX Embedding Smoke Test - 2026-07-08

## Result

Real model embedding was not implemented in this pass.

Reason: MLX runtime is proven on physical iPhone, but no embedding model assets or tokenizer assets are currently present. The realistic candidates require conversion and tokenizer validation before the app can honestly produce an MLX-backed sentence embedding.

## Intended Smoke Test

Future DEBUG-only launch argument:

```text
--run-mlx-embedding-smoke
```

Sentence:

```text
The waterfall I loved was in Guam.
```

Expected log format once a real model is wired:

```text
MLX embedding smoke: linked=true modelLoaded=true dimensions=<number> norm=<number> durationMs=<number> preview=<first 5 values> error="none"
```

The output must be a real model embedding. Deterministic vectors, hash vectors, random vectors, and character-frequency vectors must not be used for this diagnostic.

## Model Selection Status

| Item | Status |
| --- | --- |
| Model selected for immediate implementation | No |
| Best first candidate | `sentence-transformers/paraphrase-MiniLM-L3-v2` |
| Licence | Apache 2.0 |
| Model size | 17.4M params; exact app asset size uncertain until conversion |
| Embedding dimensions | 384 |
| Tokenizer approach | Not implemented; Hugging Face `AutoTokenizer` parity still required |
| Model assets committed | No |
| Tokenizer assets committed | No |
| Real embedding vector produced | No |
| Physical iPhone embedding validation | Not run |
| Xcode app build | Passed for generic iOS with MLX linked; no embedding model path added |

## Current App Behavior

| Area | Behavior |
| --- | --- |
| Normal recall | Deterministic RecallEngine path remains default. |
| Embedding provider | `CharacterFrequencyEmbeddingProvider` remains default. |
| MLX embedding provider | `MLXEmbeddingProvider` still fails closed without model assets. |
| VectorBridge | Still stores deterministic vectors for normal app use. |
| TestFlight-facing AI claim | None. |

## Validation Run

Commands run on this branch:

```text
cd MnemoMemory && swift test --quiet
cd MnemoIntelligence && swift test --quiet
Scripts/run_local_checks.sh fast
Scripts/run_local_checks.sh efficiency
git diff --check
xcodebuild -workspace /Users/barora/Mnemo/MnemoApp/Mnemo.xcworkspace -scheme Mnemo -destination 'generic/platform=iOS' -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build
```

Results:

- `MnemoMemory` passed.
- `MnemoIntelligence` passed.
- `Scripts/run_local_checks.sh fast` passed.
- `Scripts/run_local_checks.sh efficiency` passed.
- `git diff --check` passed.
- Xcode app build passed with MLX linked.

The Xcode build still emits the existing AppIntents metadata warning:

```text
warning: Metadata extraction skipped. No AppIntents.framework dependency found.
```

No physical iPhone embedding smoke was run because no real embedding model or tokenizer assets were added.

## Why This Is Not Production Recall

This branch has only proven:

- MLX Swift links in the app target.
- A tiny physical-device MLX array operation succeeds.
- The app can keep deterministic recall as the safe default.

It has not proven:

- model asset loading,
- tokenizer correctness,
- real semantic embeddings,
- index migration from 26-dimensional deterministic vectors to model vectors,
- recall quality,
- answer generation,
- source-grounded model composition,
- iPhone memory and battery behavior under repeated embedding.

## Validation To Perform After Real Model Assets Exist

1. App build with model and tokenizer assets.
2. Physical iPhone DEBUG launch with `--run-mlx-embedding-smoke`.
3. Confirm `dimensions=384`.
4. Confirm vector norm is finite and non-zero.
5. Confirm first five values are stable across repeated runs for the same sentence.
6. Confirm no crash, memory warning, or thermal warning.
7. Confirm normal Chat recall remains deterministic unless an explicit internal flag routes to the model path.

## Rollback Plan

If a future embedding smoke test destabilizes the app:

1. Remove the DEBUG launch hook.
2. Remove any model and tokenizer assets.
3. Keep `MLXEmbeddingProvider` fail-closed.
4. Keep `CharacterFrequencyEmbeddingProvider` as default.
5. Re-run `swift test`, local checks, and the Xcode app build.
