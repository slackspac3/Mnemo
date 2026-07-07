# Design Polish Validation - 2026-07-07

Build under test: local working tree after `3ea0052d3488be9f65fc528105b987cece9d98c4`

Simulator used: iPhone 17 Pro, iOS 26.4, UDID `8F8259E7-F4C0-472A-833D-CD9BCD443425`

## Summary

This pass focused on making Mnemo feel calmer, clearer, more native, and more honest without changing the validated V1 memory loop. No sign-up, Apple Sign In, backend identity, Foundation Models, MLX inference, cloud LLM fallback, autonomous actions, or new product features were added.

## Validation Table

| Screen / Flow | Polish applied | Apple-aligned principle | Validation method | Outcome | Notes |
| --- | --- | --- | --- | --- | --- |
| Onboarding | Reframed around private local memory, source-backed recall, optional App Lock, optional iCloud setup later, and first memory. Removed selectable future Cloud Assist and inactive reminder choices. | Progressive disclosure and honest capability framing. | Source review and app build. | Pass | Onboarding completion persistence unchanged. |
| Chat landing | Updated hierarchy to “What do you want to remember?”, made Write Memory primary, kept Voice/Camera/Photo secondary, added local-storage note. | Clear empty state and primary action hierarchy. | XcodeBuildMCP simulator snapshot and `Scripts/run_local_checks.sh ui`. | Pass | Snapshot exposed updated landing text and capture identifiers. |
| Text capture | Added focused text input, placeholder example, “Review Memory” action, and “Review memory” confirmation copy. Replaced raw confidence percentage with readiness labels. | Native input behavior and user-facing feedback. | XcodeBuildMCP simulator snapshot of capture sheet. | Pass | Keyboard appears on open as expected; action area shifts below keyboard. |
| Browse | Changed memory cards to a calmer single-column library style with source/date metadata and improved no-memory/no-match empty states. | Readable adaptive list layout. | Source review and app build. | Pass | Full Browse flow remains covered by previous simulator smoke validation; no new navigation logic added. |
| Chat recall | Preserved existing recall UI and identifiers; tightened input placeholder and disabled whitespace-only send. | Predictable input and stable validated behavior. | `Scripts/run_local_checks.sh fast`, `efficiency`, and `ui`. | Pass | RecallEngine tests and simulator smoke passed. |
| Source cards | Renamed to source-memory language, added chevron affordance and VoiceOver label/value/hint. | Source transparency and tappable affordance. | Source review and app build. | Pass | Existing source-card identifiers preserved. |
| Memory Detail | Replaced raw confidence/persistence percentages with “Review status” and “Recall priority”; changed non-on-device wording to “External Processing”; made Archive confirmation non-destructive role. | User control and clear destructive semantics. | Source review and app build. | Pass | Permanent delete remains destructive and confirmed. |
| Settings | Added no-account privacy copy, clarified Cloud Assist unavailable in this build, kept Sense rows as coming later, and retained App Lock copy. | Honest settings and current capability clarity. | XcodeBuildMCP simulator Settings snapshot. | Pass | Snapshot exposed App Lock toggle and supporting copy. |
| App Lock | Changed locked state from fading overlay to replacement screen, added stronger lock card, generic unlock icon, and no-account footer. | Privacy-preserving locked state and accurate LocalAuthentication copy. | Source review and app build. | Pass | Real Face ID/passcode behavior remains physical-device-only. |
| Delete All Data | No behavior change; copy remains destructive and App Lock reset path remains from previous pass. | Clear destructive confirmation. | Existing package checks and source review. | Pass | Physical-device App Lock delete-all validation still pending. |
| Dark Mode | Switched shared surface/text tokens toward semantic colors and checked dark-mode semantic snapshot. | Dark-mode adaptation and contrast. | XcodeBuildMCP simulator appearance switch plus snapshot. | Pass | First appearance switch failed inside sandboxed CoreSimulator; rerun with approved XcodeBuildMCP command succeeded. |
| Dynamic Type | Typography tokens moved to semantic text styles and several fixed action heights changed to minimum heights. | Dynamic Type and large text support. | Source review and package/app builds. | Partial | Full large-accessibility-size visual inspection remains design debt. |

## Commands Run

```sh
swift test --quiet # in MnemoUI
swift test --quiet # in MnemoMemory
xcodebuildmcp simulator build-and-run --workspace-path /Users/barora/Mnemo/MnemoApp/Mnemo.xcworkspace --scheme Mnemo --simulator-id 8F8259E7-F4C0-472A-833D-CD9BCD443425 --configuration Debug --output text
xcodebuildmcp ui-automation snapshot-ui --simulator-id 8F8259E7-F4C0-472A-833D-CD9BCD443425 --output text
xcodebuildmcp simulator-management set-appearance --simulator-id 8F8259E7-F4C0-472A-833D-CD9BCD443425 --mode dark --output text
xcodebuildmcp ui-automation snapshot-ui --simulator-id 8F8259E7-F4C0-472A-833D-CD9BCD443425 --output text
xcodebuildmcp simulator-management set-appearance --simulator-id 8F8259E7-F4C0-472A-833D-CD9BCD443425 --mode light --output text
Scripts/run_local_checks.sh fast
Scripts/run_local_checks.sh efficiency
MNEMO_SIMULATOR_ID=8F8259E7-F4C0-472A-833D-CD9BCD443425 Scripts/run_local_checks.sh ui
```

Results:

- `MnemoUI` package test: passed.
- `MnemoMemory` package tests and efficiency tests: passed.
- XcodeBuildMCP app build/run: passed, zero build diagnostics.
- Light/dark semantic snapshots: passed; key landing actions and identifiers present.
- `Scripts/run_local_checks.sh fast`: passed across all Swift packages and `git diff --check`.
- `Scripts/run_local_checks.sh efficiency`: passed.
- `Scripts/run_local_checks.sh ui`: passed; DEBUG simulator smoke build/run succeeded and captured updated landing UI.

## Remaining Design Debt

- Full manual large Dynamic Type inspection remains pending.
- Physical-device validation remains required for real Face ID/Touch ID/passcode prompts, microphone, Speech recognition, camera, photo library, OCR quality, iCloud backup/restore, notifications, file protection while locked, and app-switcher privacy.
- Browse and Memory Detail could later move further toward native `List`/`Form` section styling if needed, but this pass intentionally avoided a navigation rewrite.
- Floating capture positioning still uses the existing overlay pattern; no behavior change was made in this polish pass.
