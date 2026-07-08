# Embedding Model Decision - 2026-07-08

## Context

Branch: `mlx-embedding-spike`

Mnemo has passed a real MLX runtime smoke test on physical iPhone:

```text
MLX runtime smoke: linked=true passed=true durationMs=718.17 preview="1 + 2 = 3.0" error="none"
Type: stdio
```

That proves MLX Swift links and executes a tiny array operation in the app target. It does not prove model loading, tokenization, embedding inference, semantic retrieval, or answer generation.

## Current Code Path

| Area | Current state | Production impact |
| --- | --- | --- |
| `MLXRuntimeSmokeTest` | DEBUG-only scalar operation behind `--run-mlx-runtime-smoke`. | No production behavior change. |
| `MLXEmbeddingProvider` | Fails closed unless model assets are configured and present. | No MLX vectors are produced. |
| `EmbeddingProvider` | Boundary exists with provider metadata and execution scope. | Ready for real model provider later. |
| `EmbeddingHelper` | Defaults to `CharacterFrequencyEmbeddingProvider`. | Deterministic recall remains default. |
| `VectorBridge` | Stores local vectors and rejects dimension mismatch at search time. | Still uses 26-dimensional deterministic vectors. |
| `AICoreFlags` | MLX embeddings off by default; deterministic fallback on. | TestFlight behavior remains stable. |

## MLX-Backed Vector Rule

A vector may only be described as MLX-backed if all of these are true:

1. MLX runtime is linked.
2. Model assets are present.
3. Tokenizer assets are present.
4. The model loads successfully.
5. Output dimensions are known.
6. The vector comes from model inference.

Do not label deterministic vectors as MLX-backed. Do not create random vectors. Do not use hash vectors. Do not use character-frequency vectors as the MLX embedding result.

## Model Options

| Option | Model name | Source repository | Licence | Model size | Embedding dimensions | Tokenizer requirement | Can MLX Swift run directly? | Conversion needed | Bundle or download | Memory risk | Latency risk | App Store risk | Privacy impact | TestFlight suitability | Recommendation |
| --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Very small sentence embedding | `sentence-transformers/paraphrase-MiniLM-L3-v2` | https://huggingface.co/sentence-transformers/paraphrase-MiniLM-L3-v2 | Apache 2.0 | 17.4M params; exact pruned app asset size uncertain until converted | 384 | Hugging Face `AutoTokenizer`; BERT-style tokenizer assets required | No direct app-ready MLX Swift path confirmed | Yes, PyTorch/Safetensors plus tokenizer need conversion or a Swift tokenizer/runtime path | Could be bundled after conversion if asset size is accepted; no user download for this spike | Low to moderate, but unmeasured on iPhone | Likely low to moderate, but unmeasured | Low if bundled with licence notices; risk if unreviewed conversion assets are added | Local-only if bundled | Best first candidate after a reproducible conversion path exists | Primary candidate for the first real embedding smoke test, but not safe to add today without conversion and tokenizer validation |
| Better small retrieval model | `BAAI/bge-small-en-v1.5` | https://huggingface.co/BAAI/bge-small-en-v1.5 | MIT; model card states released models can be used commercially free of charge | 33.4M params; exact pruned app asset size uncertain until converted | 384 | Hugging Face `AutoTokenizer`; BERT-style tokenizer assets required | No direct app-ready MLX Swift path confirmed | Yes, PyTorch/Safetensors plus tokenizer need conversion or a Swift tokenizer/runtime path | Could be bundled after conversion, but size and memory must be measured; user-approved download may be better later | Moderate | Moderate | Low to moderate if bundled with licence notices; higher if downloads are introduced | Local-only if bundled or user-approved local download | Good quality candidate after the tiny model spike | Preferred quality target after the tiny spike proves the full tokenizer/model pipeline |
| Safe fallback | `CharacterFrequencyEmbeddingProvider` or future Core ML candidate | Current Mnemo source; Core ML model TBD if chosen later | Mnemo internal for deterministic provider; Core ML model licence TBD | No external model; 26 float dimensions | 26 for deterministic provider | None | Not MLX | None for deterministic provider | Already in app | Very low | Very low | Very low | Local-only | Already suitable for TestFlight fallback | Keep as default until real model assets, tokenizer, and MLX inference pass on device |

## Decision

Do not implement a fake MLX embedding in this pass.

`sentence-transformers/paraphrase-MiniLM-L3-v2` is the best first real model candidate because it is smaller than `all-MiniLM-L6-v2` and `bge-small-en-v1.5`, has 384-dimensional sentence embeddings, and has an Apache 2.0 licence. However, it still requires:

- a reproducible conversion from Hugging Face weights to MLX-loadable assets,
- bundled tokenizer assets,
- a Swift tokenizer path,
- an on-device model load test,
- measured iPhone latency and memory use,
- explicit app asset-size acceptance.

Until those are resolved, `MLXEmbeddingProvider` should remain fail-closed and `CharacterFrequencyEmbeddingProvider` should remain the default.

## Next Safe Spike

1. Convert `sentence-transformers/paraphrase-MiniLM-L3-v2` to a minimal MLX-compatible asset set outside the app repo.
2. Prove tokenizer parity against Hugging Face Python for the sentence: `The waterfall I loved was in Guam.`
3. Add the converted model and tokenizer to a temporary local-only path, not git.
4. Add a DEBUG-only smoke test that loads the model, embeds one sentence, prints dimensions, norm, first five values, and duration.
5. Only after app build and physical iPhone validation pass, decide whether any small model assets should be committed, delivered as On-Demand Resources, or downloaded with explicit user approval.
