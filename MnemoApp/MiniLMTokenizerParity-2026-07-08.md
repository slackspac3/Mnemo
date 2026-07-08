# MiniLM Tokenizer Parity - 2026-07-08

## Result

Tokenizer parity was implemented for two fixed reference sentences:

```text
The waterfall I loved was in Guam.
```

```text
The hyperpersonalised memory resurfaced unexpectedly.
```

This is tokenizer parity only. It is not model loading, MLX inference, embedding generation, production recall, Chat integration, or VectorBridge wiring.

## Waterfall Reference Output

Generated with:

```text
Tools/EmbeddingModelSpike/scripts/reference_minilm_tokens.py
```

Reference source:

```text
Hugging Face AutoTokenizer.from_pretrained("sentence-transformers/paraphrase-MiniLM-L3-v2")
```

Tokenizer class:

```text
BertTokenizerFast
```

Token IDs:

```text
[101, 1996, 14297, 1045, 3866, 2001, 1999, 16162, 1012, 102]
```

Attention mask:

```text
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
```

Tokens:

```text
["[CLS]", "the", "waterfall", "i", "loved", "was", "in", "guam", ".", "[SEP]"]
```

Token type IDs:

```text
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

## Multi-Piece WordPiece Reference Output

Selected sentence:

```text
The hyperpersonalised memory resurfaced unexpectedly.
```

This sentence was selected because Hugging Face `BertTokenizerFast` produces continuation tokens beginning with `##`.

Token IDs:

```text
[101, 1996, 23760, 28823, 5084, 3638, 24501, 3126, 12172, 2094, 14153, 1012, 102]
```

Attention mask:

```text
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
```

Tokens:

```text
["[CLS]", "the", "hyper", "##personal", "##ised", "memory", "res", "##ur", "##face", "##d", "unexpectedly", ".", "[SEP]"]
```

WordPiece continuation tokens:

```text
["##personal", "##ised", "##ur", "##face", "##d"]
```

Token type IDs:

```text
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

## Swift Approach

Added a test-only MiniLM WordPiece tokenizer inside `MnemoMemory` tests.

The test:

- reads the committed MiniLM `vocab.txt` fixture,
- lowercases and basic-tokenizes the fixed sentence,
- applies greedy WordPiece tokenization,
- adds `[CLS]` and `[SEP]`,
- emits token IDs, token type IDs, attention mask, and token strings,
- compares exactly against the Hugging Face fixtures,
- asserts the multi-piece fixture includes at least one `##` continuation token.

## Committed Tokenizer Files

| File | Size | Purpose | Licence note |
| --- | ---: | --- | --- |
| `MnemoMemory/Tests/MnemoMemoryTests/Fixtures/minilm_vocab.txt` | 231,508 bytes | Test-only WordPiece vocabulary | Source model card licence is Apache 2.0 |
| `MnemoMemory/Tests/MnemoMemoryTests/Fixtures/minilm_waterfall_tokens.json` | tiny | Hand-verified reference metadata | Tokenizer metadata only, no weights |
| `MnemoMemory/Tests/MnemoMemoryTests/Fixtures/minilm_wordpiece_tokens.json` | tiny | Hand-verified multi-piece reference metadata | Tokenizer metadata only, no weights |

No `tokenizer.json`, model weights, converted model artifacts, caches, or generated binaries were committed.

## Remaining Blockers

- Tokenizer parity is proven for two sentences only.
- Need broader tokenizer parity tests for punctuation, casing, unknown tokens, truncation, and additional multi-piece edge cases.
- Need pooling parity against SentenceTransformers mean pooling.
- Need normalisation parity.
- Need converted model weights.
- Need model loading path through `MLXNN` or `MLXEmbedders`.
- Need physical iPhone model-load and embedding latency/memory validation.

## Next Recommended Step

Add pooling and normalisation parity tests against a Python SentenceTransformers reference before attempting any iPhone embedding smoke. Then evaluate whether to add `MLXNN`, `MLXEmbedders`, or a different embedding route.
