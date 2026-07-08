#!/usr/bin/env python3
"""Print Hugging Face MiniLM tokenizer output for the parity sentence."""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone


MODEL_ID = "sentence-transformers/paraphrase-MiniLM-L3-v2"
TEXT = "The waterfall I loved was in Guam."


def main() -> int:
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
    encoded = tokenizer(TEXT, padding=False, truncation=True)
    tokens = tokenizer.convert_ids_to_tokens(encoded["input_ids"])

    payload = {
        "text": TEXT,
        "model": MODEL_ID,
        "input_ids": encoded["input_ids"],
        "token_type_ids": encoded.get("token_type_ids"),
        "attention_mask": encoded["attention_mask"],
        "tokens": tokens,
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
