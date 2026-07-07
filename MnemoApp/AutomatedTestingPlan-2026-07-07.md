# Automated Testing Plan - 2026-07-07

## Build Tested

- Branch: `main`
- Baseline app validation commit: `1c4084c Validate V1 app experience`
- Environment: macOS 26.5.1 (25F80), Xcode 26.6 (17F113), Swift 6.3.3

## Current Automated Coverage

| Area | Current Automation | Location | Notes |
| --- | --- | --- | --- |
| MnemoCore | Swift package tests | `MnemoCore/Tests` | Package compiles and tests independently. |
| MnemoSecurity | Swift package tests | `MnemoSecurity/Tests` | Covers local security helpers where practical. Physical file-protection behavior still requires device validation. |
| MnemoMemory | Swift package tests | `MnemoMemory/Tests` | Primary V1 regression surface: recall, SwiftData CRUD, vector index, archive/delete, validation fixture, and efficiency baseline. |
| MnemoCapture | Swift package tests | `MnemoCapture/Tests` | Package tests cover non-UI capture logic. Microphone, Speech, camera, and Photos permissions require device/app validation. |
| MnemoIntelligence | Swift package tests | `MnemoIntelligence/Tests` | Ensures current deterministic/stubbed intelligence surfaces remain honest and buildable. |
| MnemoSync | Swift package tests | `MnemoSync/Tests` | Package-level sync logic only. Real iCloud account behavior remains physical-device/manual. |
| MnemoUI | Swift package tests | `MnemoUI/Tests` | Build and package smoke coverage for shared UI module. |
| MnemoApp | Xcode build smoke | `MnemoApp/Mnemo.xcworkspace` | No app XCTest or XCUITest target currently exists. |

## New Coverage Added In This Pass

| Risk | Automated Check | Location |
| --- | --- | --- |
| Manual recall validation regresses | 50-query recall fixture remains passing, including mutation/delete cases | `MnemoMemory/Tests/MnemoMemoryTests/ManualRecallFixture.swift`, `RecallEngineTests.swift` |
| Archive still recalled through vector index | `archiveAndUnindex` hides archived memory and removes vector row | `VectorBridgeTests.swift` |
| Stale vector rows after restore/rebuild | `rebuildIndex` wipes stale rows and excludes archived records | `VectorBridgeTests.swift` |
| Permanent delete leaves index residue | `deletePermanently` removes SwiftData record and orphan vector row | `VectorBridgeTests.swift` |
| Test vector DB uses app storage | `VectorBridge()` resolves to a temp path during SwiftPM tests | `VectorBridgeTests.swift` |
| No-match answers leak stale citations | Recall no-match cases assert empty citation IDs and citation payloads | `RecallEngineTests.swift` |
| Recall/vector performance drifts badly | Conservative latency guardrails for 30, 100, 500, and 1,000 records | `EfficiencyBaselineTests.swift` |

## What Belongs In Package Tests

- `RecallEngine` ranking, answer extraction, caveats, no-match behavior, source IDs, and update-target selection.
- `MemoryCRUD` insert, index, archive, unarchive if added later, permanent delete, and rebuild-index behavior.
- `VectorBridge` temp-path isolation, upsert/search/delete/wipe, and local latency baselines.
- Text-capture trimming and empty-input rejection.
- Backup/restore transformation logic that can run without a real iCloud account.

## What Belongs In App Or UI Tests

These should be added only after a small, intentional app test target is created:

- First-run onboarding completion.
- Text capture sheet save path.
- Browse shows saved memory.
- Chat recall answer and source-card visibility.
- Source-card tap-through opens the correct `MemoryDetailView`.
- Last-cited update flow through real chat UI.
- Archive/delete UI confirmation and error display.

Current decision: do not add a fragile UI test target in this pass. The app has no existing XCTest/XCUITest target, and the current priority is keeping the V1 loop stable with package-level regression coverage.

## What Requires Physical Device

- Microphone permission and Apple Speech recognition.
- Camera permission and live capture.
- Photo library permission and OCR from selected images.
- Notification permission, when an active notification feature exists.
- iCloud backup/restore with a signed-in user account.
- Locked-device file protection behavior.

## What Should Not Be Automated Yet

- Foundation Models, MLX inference, and cloud LLM fallback; these are not production paths.
- Broad Mnemo Sense behavior, Memory Moments, or automatic thread suggestions; these are inactive or future-facing.
- Full semantic recall expectations beyond the deterministic validation set.
- App Store privacy-label assertions that require physical-device and account verification.

## Repeatable Commands

Fast local checks:

```sh
Scripts/run_local_checks.sh fast
```

Efficiency baseline:

```sh
Scripts/run_local_checks.sh efficiency
```

Optional app smoke build with XcodeBuildMCP:

```sh
MNEMO_SIMULATOR_ID=<simulator-udid> Scripts/run_local_checks.sh app
```
