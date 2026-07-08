# MiniLM Conversion Feasibility - 2026-07-08

## Scope

Branch: `mlx-embedding-spike`

Goal: determine whether `sentence-transformers/paraphrase-MiniLM-L3-v2` can be prepared into local artifacts that could later be loaded by MLX Swift on iPhone.

This is not app integration, Chat recall replacement, source-card wiring, VectorBridge production wiring, or local answer generation.

## Official Sources Checked

- Hugging Face model card and file tree: https://huggingface.co/sentence-transformers/paraphrase-MiniLM-L3-v2
- MLX Swift: https://github.com/ml-explore/mlx-swift
- MLX Swift Examples: https://github.com/ml-explore/mlx-swift-examples
- MLX Swift LM: https://github.com/ml-explore/mlx-swift-lm

## Model Summary

| Area | Finding |
| --- | --- |
| Model name | `sentence-transformers/paraphrase-MiniLM-L3-v2` |
| Source repository | https://huggingface.co/sentence-transformers/paraphrase-MiniLM-L3-v2 |
| Licence | Apache 2.0 |
| Parameter count | 17.4M params |
| Repository size | Hugging Face file tree reports `677 MB`, including multiple formats. |
| Primary safe weights | `model.safetensors`, 69.6 MB |
| Other weight formats | `pytorch_model.bin`, 69.6 MB, pickle-backed; `tf_model.h5`, 69.6 MB; ONNX/OpenVINO folders also exist. |
| Embedding dimensions | 384 |
| Architecture type | SentenceTransformers wrapper over `BertModel` / MiniLM-style encoder. |
| Max sequence length | 128 from the SentenceTransformers architecture listing. |
| Pooling strategy | Mean token pooling. `pooling_mode_mean_tokens = true`, CLS/max pooling false. |
| Normalisation requirement | Model card examples show sentence embeddings; normalisation is not explicit in the SentenceTransformers snippet for this model. For retrieval in Mnemo, output should be L2-normalised before indexing unless parity testing proves SentenceTransformers already normalises. Marked uncertain. |

## Required Artifact Checklist

| Artifact | Purpose | Source status | Needed for iPhone path |
| --- | --- | --- | --- |
| `config.json` | Transformer/model config | Present, 629 bytes | Yes |
| `model.safetensors` | Safe model weights | Present, 69.6 MB | Yes, unless converted into another MLX format |
| `tokenizer.json` | Fast tokenizer definition | Present, 466 kB | Yes |
| `tokenizer_config.json` | Tokenizer config | Present, 314 bytes | Yes |
| `vocab.txt` | WordPiece vocabulary | Present, 232 kB | Yes |
| `special_tokens_map.json` | Special token IDs | Present, 112 bytes | Yes |
| `modules.json` | SentenceTransformers module graph | Present, 229 bytes | Yes for parity/config validation |
| `sentence_bert_config.json` | SentenceTransformers config | Present, 53 bytes | Yes for parity/config validation |
| `config_sentence_transformers.json` | SentenceTransformers package config | Present, 122 bytes | Yes for parity/config validation |
| `1_Pooling/config.json` | Pooling layer config | Present in `1_Pooling` folder | Yes |

## MLX Swift Feasibility

| Question | Answer |
| --- | --- |
| Can MLX Swift load this directly? | Not safely confirmed. MLX can load arrays/safetensors, but a full MiniLM encoder also needs model architecture code, tokenizer, masking, pooling, and normalisation. |
| Is conversion required? | Yes, unless using an official MLXEmbedders/MLX Swift LM path that already supports this architecture and artifact layout. A direct raw `model.safetensors` load is not enough. |
| Are MLX products beyond `MLX` likely needed? | Yes. MiniLM inference almost certainly needs `MLXNN` for neural network layers, and possibly `MLXEmbedders` from `mlx-swift-lm` if we use the official reusable embedding implementation path. |
| Is a tokenizer implementation needed? | Yes. The model uses Hugging Face tokenizer artifacts. The practical Swift path is likely `swift-transformers` `Tokenizers`, or a small WordPiece implementation with parity tests. |
| Can `tokenizer.json` be used directly in Swift? | Likely possible through `swift-transformers` `Tokenizers`, based on MLX Swift LM guidance, but not validated in this repo. |
| Is final iPhone path realistic? | Yes, but not as a no-dependency app-only change. It needs tokenizer dependency evaluation, model conversion/loading design, DEBUG smoke validation, memory/latency measurement, and an asset delivery decision. |

## Conversion Attempt

No conversion was attempted in this pass.

Reason: no safe official one-command conversion path for this exact SentenceTransformers MiniLM model was identified within the current app dependency set. MLX Swift supports arrays and lower-level model construction. MLX Swift LM documents reusable libraries, downloader/tokenizer integrations, and `MLXEmbedders`, but adding those products is a dependency and app integration decision that should be made separately after tokenizer parity is proven.

## Local Tool Validation

Created `Tools/EmbeddingModelSpike/` with docs-only/local-only tooling:

- `scripts/check_minilm_assets.py`
- `scripts/prepare_minilm_local.sh`

Validation run:

```text
Tools/EmbeddingModelSpike/scripts/check_minilm_assets.py --local-only
```

Result:

- script ran successfully,
- no network metadata lookup was attempted,
- no model or tokenizer artifacts were downloaded,
- no local artifact directory was committed,
- all expected model/tokenizer files correctly reported as missing.

## Blockers and Unknowns

| Area | Blocker / Unknown |
| --- | --- |
| Tokenizer parity | Need to prove the Swift tokenizer produces the same token IDs, attention mask, truncation, and special tokens as Hugging Face for representative Mnemo inputs. |
| Model architecture | Need to confirm whether `MLXEmbedders` supports this exact MiniLM/SentenceTransformers layout or whether custom Bert/MiniLM encoder code is needed. |
| Weight format | Need to confirm whether the existing `model.safetensors` can be loaded directly by the chosen Swift path or must be converted/renamed/repacked. |
| Pooling | Need to implement mean pooling with attention-mask weighting and compare against SentenceTransformers output. |
| Normalisation | Need parity test for whether final vectors should be L2-normalised by Mnemo after pooling. |
| Asset delivery | Need to decide bundled asset, On-Demand Resource, or user-approved local download. No model assets should enter git until this is explicit. |
| iPhone performance | Need physical-device timing and memory tests after tokenizer/model load exists. |

## Recommended Next Step

Implement a tokenizer parity spike before model loading:

1. Add a local-only Python reference script that prints Hugging Face token IDs and attention mask for `The waterfall I loved was in Guam.`
2. Add a Swift DEBUG/unit tokenizer path using a candidate tokenizer library or a minimal WordPiece implementation.
3. Compare IDs/masks exactly.
4. Only after tokenizer parity passes, add `MLXNN`/`MLXEmbedders` feasibility code and attempt model load in a DEBUG-only app smoke.

This keeps the current TestFlight-safe app untouched while proving the hardest interoperability step first.
