#!/usr/bin/env bash
set -euo pipefail

MODEL_ID="sentence-transformers/paraphrase-MiniLM-L3-v2"
BASE_URL="https://huggingface.co/${MODEL_ID}/resolve/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPIKE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARTIFACT_DIR="${SPIKE_DIR}/local_artifacts/paraphrase-MiniLM-L3-v2"
INCLUDE_WEIGHTS="false"

if [[ "${1:-}" == "--include-weights" ]]; then
  INCLUDE_WEIGHTS="true"
fi

download_file() {
  local relative_path="$1"
  local url="${BASE_URL}/${relative_path}"
  local destination="${ARTIFACT_DIR}/${relative_path}"
  mkdir -p "$(dirname "${destination}")"
  if [[ -f "${destination}" ]]; then
    echo "status=present path=${relative_path}"
    return
  fi
  echo "status=downloading path=${relative_path}"
  curl --fail --location --silent --show-error "${url}" --output "${destination}"
}

mkdir -p "${ARTIFACT_DIR}"

download_file "config.json"
download_file "config_sentence_transformers.json"
download_file "modules.json"
download_file "sentence_bert_config.json"
download_file "1_Pooling/config.json"
download_file "tokenizer.json"
download_file "tokenizer_config.json"
download_file "special_tokens_map.json"
download_file "vocab.txt"

if [[ "${INCLUDE_WEIGHTS}" == "true" ]]; then
  download_file "model.safetensors"
else
  echo "status=skipped path=model.safetensors reason=pass --include-weights to download weights"
fi

echo "manifest:"
find "${ARTIFACT_DIR}" -type f | sort | while read -r file; do
  relative="${file#${ARTIFACT_DIR}/}"
  bytes="$(wc -c < "${file}" | tr -d ' ')"
  case "${relative}" in
    model.safetensors) role="weights" ;;
    tokenizer.json|tokenizer_config.json|special_tokens_map.json|vocab.txt) role="tokenizer" ;;
    1_Pooling/config.json) role="pooling" ;;
    *) role="config" ;;
  esac
  echo "path=${relative} bytes=${bytes} role=${role} status=present"
done

echo "note=All files are under ignored local_artifacts. Do not commit generated artifacts."
