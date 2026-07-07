#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-fast}"

PACKAGES=(
  MnemoCore
  MnemoSecurity
  MnemoMemory
  MnemoCapture
  MnemoIntelligence
  MnemoSync
  MnemoUI
)

usage() {
  cat <<'USAGE'
Usage: Scripts/run_local_checks.sh [fast|efficiency|app|physical-pending]

fast              Run Swift package tests and git diff whitespace checks.
efficiency        Run MnemoMemory efficiency baseline tests.
app               Build and run the app with XcodeBuildMCP if MNEMO_SIMULATOR_ID is set.
physical-pending  Print V1 flows that still need physical-device validation.
USAGE
}

run_package_tests() {
  for package in "${PACKAGES[@]}"; do
    echo "==> swift test --quiet in ${package}"
    (cd "${ROOT_DIR}/${package}" && swift test --quiet)
  done
}

run_hygiene_checks() {
  echo "==> git diff --check"
  (cd "${ROOT_DIR}" && git diff --check)
}

run_efficiency() {
  echo "==> MnemoMemory efficiency baseline"
  (cd "${ROOT_DIR}/MnemoMemory" && swift test --quiet --filter EfficiencyBaselineTests)
}

run_app_smoke() {
  if ! command -v xcodebuildmcp >/dev/null 2>&1; then
    echo "xcodebuildmcp is not installed; skipping app smoke build."
    return 0
  fi

  if [[ -z "${MNEMO_SIMULATOR_ID:-}" ]]; then
    echo "Set MNEMO_SIMULATOR_ID to run the app smoke build; skipping."
    return 0
  fi

  xcodebuildmcp simulator build-and-run \
    --workspace-path "${ROOT_DIR}/MnemoApp/Mnemo.xcworkspace" \
    --scheme Mnemo \
    --simulator-id "${MNEMO_SIMULATOR_ID}" \
    --output json
}

case "${MODE}" in
  fast)
    run_package_tests
    run_hygiene_checks
    ;;
  efficiency)
    run_efficiency
    ;;
  app)
    run_app_smoke
    ;;
  physical-pending)
    cat <<'PENDING'
Physical-device validation still required:
- Microphone permission, recording, and Speech recognition.
- Camera permission and live capture.
- Photo library permission and image OCR.
- Notification permission if future active notification features are enabled.
- iCloud backup/restore with a signed-in account.
- Locked-device file protection behavior.
- App Lock Face ID, Touch ID, device passcode fallback, cancelled prompts, and background/force-close behavior.
PENDING
    ;;
  *)
    usage
    exit 64
    ;;
esac
