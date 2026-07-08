#!/usr/bin/env python3
"""Inspect expected MiniLM embedding model artifacts without committing them."""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path


MODEL_ID = "sentence-transformers/paraphrase-MiniLM-L3-v2"
API_URL = f"https://huggingface.co/api/models/{MODEL_ID}"


@dataclass(frozen=True)
class ExpectedFile:
    path: str
    role: str
    required: bool = True


EXPECTED_FILES = [
    ExpectedFile("config.json", "config"),
    ExpectedFile("config_sentence_transformers.json", "config"),
    ExpectedFile("modules.json", "config"),
    ExpectedFile("sentence_bert_config.json", "config"),
    ExpectedFile("1_Pooling/config.json", "pooling"),
    ExpectedFile("tokenizer.json", "tokenizer"),
    ExpectedFile("tokenizer_config.json", "tokenizer"),
    ExpectedFile("special_tokens_map.json", "tokenizer"),
    ExpectedFile("vocab.txt", "tokenizer"),
    ExpectedFile("model.safetensors", "weights"),
]


def default_artifacts_dir() -> Path:
    return Path(__file__).resolve().parents[1] / "local_artifacts" / "paraphrase-MiniLM-L3-v2"


def fetch_hugging_face_metadata(timeout: float) -> dict | None:
    request = urllib.request.Request(API_URL, headers={"User-Agent": "Mnemo MiniLM asset checker"})
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
        print(f"metadata_status=unavailable error={error}", file=sys.stderr)
        return None


def sibling_size_map(metadata: dict | None) -> dict[str, int | None]:
    if not metadata:
        return {}
    result: dict[str, int | None] = {}
    for sibling in metadata.get("siblings", []):
        name = sibling.get("rfilename")
        if not isinstance(name, str):
            continue
        size = sibling.get("size")
        result[name] = size if isinstance(size, int) else None
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--artifacts-dir",
        type=Path,
        default=default_artifacts_dir(),
        help="Ignored local artifact directory to inspect.",
    )
    parser.add_argument(
        "--local-only",
        action="store_true",
        help="Skip Hugging Face API metadata lookup.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=15,
        help="Network timeout for metadata lookup.",
    )
    args = parser.parse_args()

    metadata = None if args.local_only else fetch_hugging_face_metadata(args.timeout)
    sizes = sibling_size_map(metadata)

    print(f"model={MODEL_ID}")
    print(f"artifacts_dir={args.artifacts_dir}")
    print("required_files:")

    missing_required = False
    for expected in EXPECTED_FILES:
        local_path = args.artifacts_dir / expected.path
        exists = local_path.exists()
        missing_required = missing_required or (expected.required and not exists)
        remote_size = sizes.get(expected.path)
        remote_size_text = "unknown" if remote_size is None else str(remote_size)
        status = "present" if exists else "missing"
        local_bytes = local_path.stat().st_size if exists and local_path.is_file() else 0
        print(
            f"- path={expected.path} role={expected.role} required={expected.required} "
            f"status={status} localBytes={local_bytes} remoteBytes={remote_size_text}"
        )

    print(f"ready_for_conversion={not missing_required}")
    print("note=This script does not prove MLX compatibility or produce embeddings.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
