#!/usr/bin/env python3
"""Print Hugging Face MiniLM tokenizer output for a parity sentence."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone


MODEL_ID = "sentence-transformers/paraphrase-MiniLM-L3-v2"
DEFAULT_TEXT = "The waterfall I loved was in Guam."


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print MiniLM Hugging Face tokenizer output for parity fixtures."
    )
    parser.add_argument(
        "--text",
        default=DEFAULT_TEXT,
        help="Sentence to tokenize. Defaults to the waterfall parity sentence.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        from transformers import AutoTokenizer
    except ImportError:
        print(
            "Missing dependency: transformers. Install locally with "
            "`python3 -m pip install transformers tokenizers`.",
            file=sys.stderr,
        )
        return 2

    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
    encoded = tokenizer(args.text, padding=False, truncation=True)
    tokens = tokenizer.convert_ids_to_tokens(encoded["input_ids"])

    payload = {
        "text": args.text,
        "model": MODEL_ID,
        "input_ids": encoded["input_ids"],
        "token_type_ids": encoded.get("token_type_ids"),
        "attention_mask": encoded["attention_mask"],
        "tokens": tokens,
        "has_wordpiece_continuation": any(token.startswith("##") for token in tokens),
        "model_max_length": tokenizer.model_max_length,
        "tokenizer_class": tokenizer.__class__.__name__,
        "files_required": [
            "tokenizer.json",
            "tokenizer_config.json",
            "special_tokens_map.json",
            "vocab.txt",
        ],
        "reference_source": "Hugging Face AutoTokenizer.from_pretrained",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "note": "Tokenizer metadata only. No model weights or embeddings.",
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
