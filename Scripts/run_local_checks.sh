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
Usage: Scripts/run_local_checks.sh [fast|efficiency|app|ui|physical-pending]

fast              Run Swift package tests and git diff whitespace checks.
efficiency        Run MnemoMemory efficiency baseline tests.
app               Build and run the app with XcodeBuildMCP if MNEMO_SIMULATOR_ID is set.
ui                Build/run a simulator UI smoke state and capture a semantic UI snapshot.
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
  echo "==> git diff --check (working tree)"
  (cd "${ROOT_DIR}" && git diff --check)

  if git -C "${ROOT_DIR}" rev-parse --verify --quiet origin/main >/dev/null; then
    local merge_base
    merge_base="$(git -C "${ROOT_DIR}" merge-base HEAD origin/main)"
    echo "==> git diff --check (origin/main merge-base to worktree)"
    (cd "${ROOT_DIR}" && git diff --check "${merge_base}")
  fi
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

run_ui_smoke() {
  if ! command -v xcodebuildmcp >/dev/null 2>&1; then
    echo "xcodebuildmcp is not installed; cannot run simulator UI smoke."
    return 127
  fi

  if [[ -z "${MNEMO_SIMULATOR_ID:-}" ]]; then
    echo "Set MNEMO_SIMULATOR_ID to run simulator UI smoke."
    return 64
  fi

  local build_run_arguments
  build_run_arguments="$(printf \
    '{"workspacePath":"%s","scheme":"Mnemo","simulatorId":"%s","launchArgs":["--ui-testing","--reset-data-on-launch","--skip-onboarding-if-needed"]}' \
    "${ROOT_DIR}/MnemoApp/Mnemo.xcworkspace" \
    "${MNEMO_SIMULATOR_ID}")"

  xcodebuildmcp simulator build-and-run \
    --json "${build_run_arguments}" \
    --output json

  local snapshot_output
  snapshot_output="$(xcodebuildmcp simulator snapshot-ui \
    --simulator-id "${MNEMO_SIMULATOR_ID}" \
    --output json)"
  printf '%s\n' "${snapshot_output}"

  local required_target
  for required_target in \
    '"didError": false' \
    'chat.input' \
    'tab.settings' \
    'capture.text.open' \
    'capture.voice.open' \
    'capture.camera.open' \
    'capture.photo.open' \
    '|tab|Recall|1|' \
    '|tab|Memories|0|'; do
    case "${snapshot_output}" in
      *"${required_target}"*) ;;
      *)
        echo "UI smoke assertion failed: missing ${required_target}" >&2
        return 1
        ;;
    esac
  done
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
  ui)
    run_ui_smoke
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
