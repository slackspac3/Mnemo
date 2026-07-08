# MiniLM Tokenizer Parity - 2026-07-08

## Result

Tokenizer parity was implemented for one fixed reference sentence:

```text
The waterfall I loved was in Guam.
```

This is tokenizer parity only. It is not model loading, MLX inference, embedding generation, production recall, Chat integration, or VectorBridge wiring.

## Reference Output

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

## Swift Approach

Added a test-only MiniLM WordPiece tokenizer inside `MnemoMemory` tests.

The test:

- reads the committed MiniLM `vocab.txt` fixture,
- lowercases and basic-tokenizes the fixed sentence,
- applies greedy WordPiece tokenization,
- adds `[CLS]` and `[SEP]`,
- emits token IDs, token type IDs, attention mask, and token strings,
- compares exactly against the Hugging Face fixture.

## Committed Tokenizer Files

| File | Size | Purpose | Licence note |
| --- | ---: | --- | --- |
| `MnemoMemory/Tests/MnemoMemoryTests/Fixtures/minilm_vocab.txt` | 231,508 bytes | Test-only WordPiece vocabulary | Source model card licence is Apache 2.0 |
| `MnemoMemory/Tests/MnemoMemoryTests/Fixtures/minilm_waterfall_tokens.json` | tiny | Hand-verified reference metadata | Tokenizer metadata only, no weights |

No `tokenizer.json`, model weights, converted model artifacts, caches, or generated binaries were committed.

## Remaining Blockers

- Tokenizer parity is proven for one sentence only.
- Need broader tokenizer parity tests for punctuation, casing, unknown tokens, truncation, and multi-piece words.
- Need pooling parity against SentenceTransformers mean pooling.
- Need normalisation parity.
- Need model loading path through `MLXNN` or `MLXEmbedders`.
- Need physical iPhone model-load and embedding latency/memory validation.

## Next Recommended Step

Add a second tokenizer parity fixture that forces multi-piece WordPiece output, for example a sentence containing an uncommon word that splits into `##` subtokens. Then evaluate whether to add `swift-transformers` `Tokenizers` or keep a minimal internal tokenizer for DEBUG-only smoke tests.
