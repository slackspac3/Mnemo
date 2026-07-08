# MLX Embedding Model Load Route - 2026-07-08

## Scope

Branch:

```text
mlx-embedding-spike
```

Selected embedding model:

```text
sentence-transformers/paraphrase-MiniLM-L3-v2
```

This is a feasibility decision document only. It does not add model weights, converted model artifacts, package dependencies, Swift embedding generation, production recall wiring, Chat changes, VectorBridge indexing, source-card changes, or user-facing AI claims.

## Current State

Mnemo has already proven:

- MLX Swift links in the app target.
- A real MLX runtime operation passed on physical iPhone.
- MiniLM WordPiece tokenizer parity passes for two sentences.
- Pooling and normalisation references exist for the selected model.
- Mean-token pooling is the required pooling strategy.
- There is no SentenceTransformers `Normalize` module for this model.
- `normalize_embeddings` is `false` by default.
- Embedding dimension is `384`.
- Deterministic recall remains default.

Current app dependency state:

- `MnemoApp` links `mlx-swift` directly.
- The app currently links the `MLX` product only.
- `Package.resolved` pins `mlx-swift` to `0.31.6`.

## Official Sources Checked

Official repositories inspected:

- `https://github.com/ml-explore/mlx-swift`
- `https://github.com/ml-explore/mlx-swift-lm`
- `https://github.com/ml-explore/mlx-swift-examples`

Relevant official source observations:

- `mlx-swift` exposes products including `MLX`, `MLXNN`, `MLXOptimizers`, `MLXRandom`, `MLXFFT`, `MLXLinalg`, and `MLXFast`.
- `mlx-swift-lm` exposes an `MLXEmbedders` product.
- `MLXEmbedders` depends on `MLX`, `MLXNN`, and `MLXLMCommon`.
- `MLXEmbedders` has a model type registry that includes `bert`, `roberta`, `xlm-roberta`, `distilbert`, `nomic_bert`, `qwen3`, and Gemma embedding variants.
- `MLXEmbedders` has known registered embedding model IDs including `sentence-transformers/all-MiniLM-L6-v2` and `sentence-transformers/all-MiniLM-L12-v2`.
- The selected model, `sentence-transformers/paraphrase-MiniLM-L3-v2`, is not listed as a built-in known registry constant, but its `config.json` has `model_type: "bert"`, `architectures: ["BertModel"]`, `num_hidden_layers: 3`, `hidden_size: 384`, and `num_attention_heads: 12`.

## Route A - MLXEmbedders

### Suitability

`MLXEmbedders` is the strongest first route because it already contains:

- an embedding-model container abstraction,
- a BERT model type path,
- local-directory model loading,
- tokenizer loading hooks,
- weight loading,
- a pooling abstraction,
- known MiniLM registry entries for `all-MiniLM-L6-v2` and `all-MiniLM-L12-v2`.

The selected MiniLM-L3 model is BERT-shaped, so it should be attempted with `MLXEmbedders` before building custom layers.

### Unproven Items

`MLXEmbedders` is not yet proven suitable for Mnemo because:

- `paraphrase-MiniLM-L3-v2` is not a built-in known registry constant.
- It may require a custom `ModelConfiguration(id:)` or local directory configuration.
- The local model artifact layout must match what `MLXEmbedders` expects.
- The tokenizer loader path must accept the MiniLM tokenizer files.
- The model weights may require an MLX-compatible conversion or naming convention.
- Its pooling call examples default to explicit options such as `normalize: true` for some models, while Mnemo's selected model reference requires unnormalised mean pooling.

### Package Impact

Adding this route means adding the `mlx-swift-lm` package, not only more products from `mlx-swift`.

Likely products needed:

- `MLXEmbedders`
- possibly `MLXHuggingFace`

Transitive dependencies include:

- `MLX`
- `MLXNN`
- `MLXLMCommon`
- SwiftSyntax macro dependencies used by `MLXHuggingFace`

### Duplicate-Link Risk

There is a real duplicate-link and resolution risk because Mnemo already links `mlx-swift` directly.

`mlx-swift-lm` also depends on `mlx-swift`. If Xcode resolves both to the same compatible version, this should be manageable. If the direct app `mlx-swift` package and the transitive `mlx-swift` package resolve differently, the build can become unstable or duplicate MLX symbols.

Mitigation:

1. Add `mlx-swift-lm` in a dedicated dependency/build commit only.
2. Keep the existing direct `MLX` package unless Xcode resolves duplicate package references poorly.
3. If duplicate package references appear, migrate to a single dependency graph where `mlx-swift-lm` supplies the MLX dependency consistently.
4. Validate with Xcode/xcodebuild, not SwiftPM alone.

### App Bundle / Local Loading

Official `MLXEmbedders` README shows local-directory loading. That makes it plausible for a future DEBUG-only app smoke that points to an app-bundled or developer-provided local model directory.

Do not bundle model files yet.

## Route B - MLXNN / Custom MiniLM

### Suitability

`MLXNN` is likely required under the hood because MiniLM/BERT needs:

- embeddings,
- attention layers,
- feed-forward layers,
- layer norm,
- GELU,
- token type embeddings,
- position embeddings,
- attention-mask handling.

`MLXEmbedders` already depends on `MLXNN`, which reinforces that custom MLXNN would be the lower-level fallback.

### Risks

The custom MLXNN route is significantly riskier:

- BERT/MiniLM encoder implementation would need to be owned by Mnemo or copied from MLXEmbedders.
- Weight-name mapping from Hugging Face/SentenceTransformers to MLXNN layers must be exact.
- Attention masks and token type IDs must match the Python reference.
- Pooling and normalisation must be applied exactly.
- Testing requires full-vector parity, not just first-10-value references.
- The code would be harder to maintain as MLX Swift evolves.

### Recommendation

Do not start with custom MLXNN. Use it only if `MLXEmbedders` cannot load the selected model or cannot support the required tokenizer/pooling path.

## Model Conversion / Artifact Route

### Source Files Needed

Minimum source model directory:

- `config.json`
- model weights, likely `model.safetensors` or equivalent
- `tokenizer.json`
- `tokenizer_config.json`
- `special_tokens_map.json`
- `vocab.txt`
- SentenceTransformers pooling files:
  - `modules.json`
  - `1_Pooling/config.json`
  - `sentence_bert_config.json`

Current local metadata-only artifact set is about `699 KB` without weights.

The Python reference run downloaded a weight blob of about `66 MB` into `/private/tmp/mnemo-hf-cache-embedding`. Those files were cache-only and not committed.

### Target Format

The target format is not proven yet.

Possible outcomes:

1. `MLXEmbedders` can read Hugging Face/SentenceTransformers files directly from a local directory.
2. `MLXEmbedders` requires converted MLX-safe weight naming or layout.
3. A separate conversion step is needed before app loading.

Until route 1 is proven, converted files must remain ignored under:

```text
Tools/EmbeddingModelSpike/local_artifacts/
```

### Asset Policy

Do not commit:

- model weights,
- converted weights,
- tokenizer caches,
- Hugging Face cache files,
- full embedding dumps,
- generated local manifests with machine paths.

Any future model asset commit needs a separate explicit decision because even a small MiniLM model is tens of MB before app-thinning/compression.

Licence note:

- The selected Hugging Face model card reports Apache 2.0 in previous Mnemo feasibility notes.
- Re-check the exact upstream model card before bundling any weights.

## Alternatives Considered

| Route | Decision | Rationale |
| --- | --- | --- |
| Add `MLXEmbedders` now | Not in this pass | Needs project/package mutation and xcodebuild validation. Better as a focused dependency spike. |
| Custom `MLXNN` MiniLM | Defer | Too much implementation risk before testing official embedder path. |
| Python conversion first | Useful only after route choice | Conversion target is unclear until `MLXEmbedders` expectations are tested. |
| Switch model | Not yet | Selected model is BERT-shaped and small enough to try with `MLXEmbedders` first. |
| Core ML interim | Viable fallback | Good fallback if MLXEmbedders cannot load MiniLM cleanly, but it would move away from the MLX-first spike goal. |

## Recommended Route

Choose:

```text
A. Add MLXEmbedders dependency and create a DEBUG-only local-directory model-load spike.
```

But do it as the next isolated task, not in this documentation pass.

The next implementation should:

1. Add `mlx-swift-lm` in the app project.
2. Link the minimum products needed for a DEBUG-only smoke, likely `MLXEmbedders` and possibly `MLXHuggingFace`.
3. Resolve duplicate `mlx-swift` package/linkage risk.
4. Build with xcodebuild for generic iOS.
5. Attempt a local-directory load for `paraphrase-MiniLM-L3-v2` from ignored local artifacts.
6. If direct load fails, record the exact failure before adding conversion code.
7. Do not wire the result to production recall.

## What Must Be Proven Before iPhone Embedding Smoke

- Xcode resolves `mlx-swift-lm` without duplicate MLX linkage.
- App target builds with `MLXEmbedders`.
- A local model directory can be found from DEBUG-only code.
- The selected MiniLM config is accepted by the BERT model registry.
- Tokenizer files load correctly.
- Weights load correctly.
- Pooling can be called with `normalize: false`.
- Output shape is `[384]`.
- A full vector matches the Python reference within an agreed tolerance.

## Why Production Recall Remains Untouched

Current deterministic recall is already TestFlight-safe and source-grounded. The MLX embedding route is not proven until model loading, tokenizer loading, pooling, output parity, latency, memory pressure, and iPhone runtime stability pass.

Until then:

- `MLXEmbeddingProvider` remains fail-closed.
- deterministic recall remains default.
- no Chat path uses MLX embeddings.
- no TestFlight-facing AI claim should be made.
