# MiniLM Pooling and Normalisation Parity - 2026-07-08

## Scope

Model:

```text
sentence-transformers/paraphrase-MiniLM-L3-v2
```

This document records a local Python numeric reference for how the selected SentenceTransformers model turns token embeddings into a sentence embedding.

This is not MLX inference, model conversion, iPhone embedding smoke, production recall wiring, Chat replacement, VectorBridge integration, or a user-facing AI claim.

## SentenceTransformers Module Config

The model modules are:

```text
0: sentence_transformers.models.Transformer
1: sentence_transformers.models.Pooling
```

Pooling config:

```json
{
  "word_embedding_dimension": 384,
  "pooling_mode_cls_token": false,
  "pooling_mode_mean_tokens": true,
  "pooling_mode_max_tokens": false,
  "pooling_mode_mean_sqrt_len_tokens": false
}
```

There is no `Normalize` module in the model module list. SentenceTransformers `encode` defaults to `normalize_embeddings=False`, so the reference embeddings below are not L2-normalised by default.

## Pooling Formula

Mean pooling:

```text
mean_pooling = sum(token_embeddings * attention_mask) / sum(attention_mask)
```

Where:

- `token_embeddings` shape is `[batch, token_count, 384]`
- `attention_mask` is expanded over the embedding dimension
- padded tokens are excluded by the mask

Default normalisation:

```text
normalise_embeddings = false
```

If normalisation is explicitly enabled later, the follow-up formula would be:

```text
embedding = embedding / L2_norm(embedding)
```

## Reference Script

Run:

```text
HF_HOME=/private/tmp/mnemo-hf-cache-embedding TOKENIZERS_PARALLELISM=false Tools/EmbeddingModelSpike/scripts/reference_minilm_embedding.py --text "The waterfall I loved was in Guam."
```

The script uses `Transformers AutoModel` with the SentenceTransformers pooling config. Model weights are downloaded to a local Hugging Face cache outside the repo. No model weights are committed.

## Reference 1 - Waterfall

Sentence:

```text
The waterfall I loved was in Guam.
```

Token IDs:

```text
[101, 1996, 14297, 1045, 3866, 2001, 1999, 16162, 1012, 102]
```

Attention mask:

```text
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
```

Token embeddings shape:

```text
[1, 10, 384]
```

Sentence embedding dimension:

```text
384
```

Embedding norm:

```text
4.942253589630127
```

First 10 values:

```text
[0.1440598964691162, 0.21177761256694794, 0.3527992367744446, 0.6709719896316528, -0.12689164280891418, -0.3926422595977783, 0.07465793192386627, 0.2153007984161377, -0.258791446685791, -0.2895522713661194]
```

## Reference 2 - Multi-Piece WordPiece

Sentence:

```text
The hyperpersonalised memory resurfaced unexpectedly.
```

Token IDs:

```text
[101, 1996, 23760, 28823, 5084, 3638, 24501, 3126, 12172, 2094, 14153, 1012, 102]
```

Attention mask:

```text
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
```

Token embeddings shape:

```text
[1, 13, 384]
```

Sentence embedding dimension:

```text
384
```

Embedding norm:

```text
4.416421413421631
```

First 10 values:

```text
[-0.23572109639644623, 0.058966152369976044, -0.04777000471949577, -0.025707433000206947, -0.18367116153240204, -0.039256446063518524, -0.07940314710140228, -0.24299976229667664, 0.2673064172267914, 0.110294409096241]
```

## Committed Fixtures

Committed numeric fixtures:

- `MnemoMemory/Tests/MnemoMemoryTests/Fixtures/minilm_waterfall_embedding_reference.json`
- `MnemoMemory/Tests/MnemoMemoryTests/Fixtures/minilm_wordpiece_embedding_reference.json`

They contain only token IDs, masks, embedding shape, pooling metadata, norm, and first 10 embedding values. They do not contain model weights or full embedding vectors.

## What Swift / MLX Must Replicate

To produce real MiniLM embeddings on iPhone, Swift/MLX must replicate:

1. MiniLM tokenizer parity.
2. Transformer model inference producing token embeddings shaped `[1, token_count, 384]`.
3. Mean-token pooling with attention-mask exclusion.
4. Default unnormalised output, unless a future pipeline explicitly requests L2-normalised embeddings.
5. Consistent float precision and output dimension.

## What Remains Blocked

- Converted model weights are not available in the app.
- No MLXNN or MLXEmbedders loading path has been selected.
- No full 384-value fixture is committed.
- No Swift or MLX code computes embeddings.
- No physical iPhone embedding smoke test has run.
- Deterministic recall remains the default path.

## Next Recommended Step

Decide the model-loading route:

1. Try `MLXEmbedders` if it supports this architecture and tokenizer path cleanly.
2. Otherwise evaluate an `MLXNN` MiniLM load using converted weights.
3. Add a DEBUG-only embedding smoke only after model loading produces a full 384-dimensional vector that matches this Python reference within a defined tolerance.
