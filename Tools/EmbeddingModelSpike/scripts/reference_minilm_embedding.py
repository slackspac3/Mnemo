#!/usr/bin/env python3
"""Print a MiniLM SentenceTransformers-style embedding reference."""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone


MODEL_ID = "sentence-transformers/paraphrase-MiniLM-L3-v2"
DEFAULT_TEXT = "The waterfall I loved was in Guam."
MAX_SEQ_LENGTH = 128
NORMALISE_EMBEDDINGS_BY_DEFAULT = False

# Keep the reference path focused on PyTorch/Transformers. Some local Python
# installs import TensorFlow/JAX side effects that can hang on low-level locks.
os.environ.setdefault("USE_TF", "0")
os.environ.setdefault("USE_FLAX", "0")
os.environ.setdefault("TRANSFORMERS_NO_TF", "1")
os.environ.setdefault("TRANSFORMERS_NO_FLAX", "1")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate MiniLM pooling and normalisation reference values."
    )
    parser.add_argument(
        "--text",
        default=DEFAULT_TEXT,
        help="Sentence to embed. Defaults to the waterfall parity sentence.",
    )
    return parser.parse_args()


def dependency_error(package: str) -> int:
    print(
        "Missing dependency: "
        f"{package}. Install locally with "
        "`python3 -m pip install sentence-transformers torch transformers`.",
        file=sys.stderr,
    )
    return 2


def mean_pool(token_embeddings, attention_mask):
    input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
    summed = (token_embeddings * input_mask_expanded).sum(dim=1)
    token_count = input_mask_expanded.sum(dim=1).clamp(min=1e-9)
    return summed / token_count


def main() -> int:
    args = parse_args()

    try:
        import torch
    except ImportError:
        return dependency_error("torch")

    try:
        from transformers import AutoModel, AutoTokenizer
    except ImportError:
        return dependency_error("transformers")

    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
    model = AutoModel.from_pretrained(MODEL_ID)
    model.eval()

    encoded = tokenizer(
        args.text,
        padding=False,
        truncation=True,
        max_length=MAX_SEQ_LENGTH,
        return_tensors="pt",
    )
    tokens = tokenizer.convert_ids_to_tokens(encoded["input_ids"][0].tolist())

    with torch.no_grad():
        model_output = model(**encoded)
        token_embeddings = model_output.last_hidden_state
        sentence_embedding = mean_pool(token_embeddings, encoded["attention_mask"])[0]

        if NORMALISE_EMBEDDINGS_BY_DEFAULT:
            sentence_embedding = torch.nn.functional.normalize(sentence_embedding, p=2, dim=0)

    norm = torch.linalg.vector_norm(sentence_embedding).item()
    first_10 = sentence_embedding[:10].tolist()

    payload = {
        "text": args.text,
        "model": MODEL_ID,
        "tokenizer_class": tokenizer.__class__.__name__,
        "model_class": model.__class__.__name__,
        "input_ids": encoded["input_ids"][0].tolist(),
        "token_type_ids": (
            encoded["token_type_ids"][0].tolist() if "token_type_ids" in encoded else None
        ),
        "attention_mask": encoded["attention_mask"][0].tolist(),
        "tokens": tokens,
        "token_count": int(encoded["attention_mask"][0].sum().item()),
        "token_embeddings_shape": list(token_embeddings.shape),
        "pooling_strategy": "mean_tokens",
        "pooling_formula": (
            "sum(token_embeddings * attention_mask) / sum(attention_mask)"
        ),
        "normalise_embeddings": NORMALISE_EMBEDDINGS_BY_DEFAULT,
        "normalisation_source": (
            "SentenceTransformers encode default is normalize_embeddings=False; "
            "model modules contain Transformer + Pooling and no Normalize module."
        ),
        "sentence_embedding_dimensions": int(sentence_embedding.shape[0]),
        "sentence_embedding_norm": norm,
        "first_10_values": first_10,
        "dtype": str(sentence_embedding.dtype).replace("torch.", ""),
        "max_seq_length": MAX_SEQ_LENGTH,
        "reference_source": (
            "Transformers AutoModel with SentenceTransformers pooling config"
        ),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "note": "Numeric reference only. No model weights or embeddings are committed.",
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
