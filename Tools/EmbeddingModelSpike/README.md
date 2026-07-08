# Embedding Model Spike Tools

This folder contains local-only tooling for the MiniLM embedding model feasibility spike.

It must not contain committed model weights, tokenizer artifacts, converted binaries, caches, logs, or virtual environments. The `.gitignore` in this folder excludes `local_artifacts/` and common model artifact formats.

## Model

```text
sentence-transformers/paraphrase-MiniLM-L3-v2
```

## Local Artifact Location

Scripts write only under:

```text
Tools/EmbeddingModelSpike/local_artifacts/
```

That directory is ignored by git.

## Metadata Check

Run:

```text
python3 Tools/EmbeddingModelSpike/scripts/check_minilm_assets.py
```

This prints:

- expected required files,
- whether local copies exist,
- Hugging Face metadata if network access is available,
- whether each file is a model weight, tokenizer file, config file, or pooling file.

It does not download model weights.

## Reference Tokenizer Output

Run:

```text
Tools/EmbeddingModelSpike/scripts/reference_minilm_tokens.py
```

This uses `transformers.AutoTokenizer` for:

```text
The waterfall I loved was in Guam.
```

To produce a reference for another sentence:

```text
Tools/EmbeddingModelSpike/scripts/reference_minilm_tokens.py --text "The hyperpersonalised memory resurfaced unexpectedly."
```

The output includes `has_wordpiece_continuation`, which is useful when creating fixtures that must exercise `##` WordPiece continuations.

If dependencies are missing, install them outside the repo:

```text
python3 -m pip install transformers tokenizers
```

Do not commit Hugging Face caches or generated logs. A tiny hand-verified tokenizer metadata fixture may be committed under package tests.

## Reference Embedding Output

Run:

```text
Tools/EmbeddingModelSpike/scripts/reference_minilm_embedding.py --text "The waterfall I loved was in Guam."
```

This uses `transformers.AutoModel` plus the SentenceTransformers pooling config to print token embedding shape, mean-pooling settings, normalisation behaviour, embedding dimension, norm, and the first 10 embedding values.

If dependencies are missing, install them outside the repo:

```text
python3 -m pip install sentence-transformers torch transformers
```

Model files are loaded through the local Hugging Face cache. Do not commit downloaded weights, caches, or full embedding dumps.

## Prepare Local Files

Run:

```text
Tools/EmbeddingModelSpike/scripts/prepare_minilm_local.sh
```

By default this downloads small config/tokenizer/pooling files only.

To also download `model.safetensors` into the ignored local artifact directory:

```text
Tools/EmbeddingModelSpike/scripts/prepare_minilm_local.sh --include-weights
```

Do not commit files produced by this script.

## Expected Manifest Format

The scripts print a manifest like:

```text
path=<relative local artifact path> bytes=<size> role=<config|tokenizer|pooling|weights> status=<present|missing>
```

Generated manifests should stay local unless they are hand-summarised in a markdown decision document without machine-specific paths.

## Conversion Status

No conversion command is included yet because no safe official one-command conversion path for this exact MiniLM/SentenceTransformers model has been validated. The next safe step is tokenizer parity, then MLX model loading feasibility.
