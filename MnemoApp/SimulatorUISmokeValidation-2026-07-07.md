# Simulator UI Smoke Validation - 2026-07-07

## Build Tested

| Item | Value |
| --- | --- |
| Base commit | `4ff18c7bc84378da61a0f726f62b9cf5ad9fbd08` (`Validate App Lock automation`) |
| Validation state | Working tree with simulator UI smoke hooks from this pass |
| Simulator target | iPhone 17e / iPhone 17 Pro simulator where available, iOS 26.4 |
| Physical device | Not available in this run |
| Account/sign-in | Not implemented; no Mnemo account is required |

## UI Automation Feasibility

The Xcode project does not currently contain an app XCTest or XCUITest target, and the shared scheme has an empty `TestAction`. Creating a new UI test target would require project-target scaffolding and additional scheme management beyond the smallest safe validation layer for this pass.

Instead, this pass adds stable accessibility identifiers for the V1 memory loop and App Lock shell, plus a repeatable simulator smoke command:

```sh
MNEMO_SIMULATOR_ID=<simulator-udid> Scripts/run_local_checks.sh ui
```

That command builds and launches the app with DEBUG-only test launch arguments:

- `--ui-testing`
- `--reset-data-on-launch`
- `--skip-onboarding-if-needed`

These arguments are ignored outside DEBUG builds and do not change production privacy, App Lock, or onboarding behavior.

## Smoke Results

| Flow | Method | Environment | Expected | Actual | Outcome | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Onboarding completion | XcodeBuildMCP simulator QA | Simulator | First-run onboarding reaches main Chat | Welcome, source-backed recall, optional App Lock/no-account, and completion screens were exercised, then main Chat appeared | Pass | No physical-device permissions were claimed and onboarding does not seed memories. |
| Text capture -> Browse -> Chat | XcodeBuildMCP simulator QA + accessibility IDs | Simulator | Correct answer and source | Saved `Mum wears size 38 shoes.`, saw it in Browse, asked `What size does mum wear?`, and Chat returned the correct answer with a source card | Pass | Stable IDs now exist for future XCUITest coverage. |
| Source card tap-through | XcodeBuildMCP simulator QA + accessibility IDs | Simulator | Opens correct memory | Tapping the primary source card opened `MemoryDetailView` for the cited Mum memory | Pass | `MemoryDetailView` has stable identifiers for title/archive/delete. |
| Last-cited update | XcodeBuildMCP simulator QA + manual bug report | Simulator/source | Updates cited memory and uses correct owner in reply | `Update that to size 39.` updated the last cited memory and follow-up recall returned `Mum` with size 39 | Pass after fix | This pass also fixes the reported update confirmation copy so it preserves `Mum's shoe size` instead of saying `Your size`. |
| Archive hides memory | XcodeBuildMCP simulator QA + accessibility IDs | Simulator | No recall after archive | Archiving the cited memory showed the empty-memory recovery panel and Browse returned to `No memories yet` | Pass | Package tests continue to cover archive recall/index behavior. |
| Permanent delete | XcodeBuildMCP simulator QA + accessibility IDs | Simulator | Deleted memory is removed from Browse | A disposable second memory was saved, permanent delete confirmation appeared, and Browse returned to `No memories yet` | Pass | Vector cleanup remains covered by package tests; stale source-card delete edge cases remain a future UI test. |
| Delete All Data | DEBUG launch args + source audit | Simulator/source | Clears memory state | `--reset-data-on-launch` wipes SwiftData models and vector store for repeatable smoke runs; Settings destructive control has a stable identifier | Prepared | The destructive in-app Delete All Data confirmation was visible/source-audited but not completed in this run. |
| Settings App Lock row | XcodeBuildMCP simulator QA + source audit | Simulator/source | Correct copy | Settings opened and showed the Security section, App Lock toggle copy, inactive Sense rows, iCloud Backup, and Delete All Data | Pass | Real LocalAuthentication prompt behavior remains physical-device-only. |
| App Lock screen shell | Accessibility IDs + source audit | Simulator/source | Covers memories when locked | App Lock screen, unlock button, and error text have stable identifiers | Prepared | No DEBUG force-lock route was added, so production lock behavior was not weakened. |
| No account UI | Source audit | Source | No sign-up/login appears | App source search found no sign-up, login, Apple Sign In, OAuth, email/password, or backend identity UI added by this pass | Pass | Mnemo remains account-free for V1. |

## UI Smoke Command Result

Command:

```sh
MNEMO_SIMULATOR_ID=8F8259E7-F4C0-472A-833D-CD9BCD443425 Scripts/run_local_checks.sh ui
```

Result:

- Build/install/launch: `SUCCEEDED`
- XcodeBuildMCP diagnostics: zero warnings, zero errors
- Runtime snapshot: `SUCCEEDED`
- Snapshot hash: `0kdlf1k`
- Snapshot confirmed target identifiers for:
  - `capture.text.open`
  - `capture.voice.open`
  - `capture.camera.open`
  - `capture.photo.open`
  - `chat.input`
  - `tab.settings`
  - `tab.browse`
  - Chat tab target
  - Threads is intentionally absent from the V1 tab bar.

## Accessibility Identifiers Added

- Onboarding: `onboarding.continue`, `onboarding.complete`
- Main navigation: `main.tabView`, `tab.chat`, `tab.browse`
- Global controls: `tab.settings`; the floating capture button keeps the legacy `tab.capture` identifier for test compatibility even though it is not a tab bar item.
- Text capture: `capture.text.open`, `capture.text.input`, `capture.text.extract`, `capture.text.review`, `capture.text.save`, `capture.text.dismiss`
- Browse: `browse.screen`, `browse.memoryCell`
- Chat: `chat.landing`, `chat.input`, `chat.send`, `chat.message.user`, `chat.message.assistant`, `chat.sourceCard`, `chat.sourceCard.primary`, `chat.sourceCard.sourceType`
- Memory detail: `memoryDetail.title`, `memoryDetail.archive`, `memoryDetail.delete`
- Settings: `settings.securitySection`, `settings.appLockToggle`, `settings.deleteAllData`
- App Lock: `appLock.screen`, `appLock.unlockButton`, `appLock.errorMessage`

Identifiers do not include private memory contents. Visible labels may still contain user-entered text where the UI already displays that text.

## Bugs Found And Fixed

- The size-update confirmation could say `Your size is now 39` after updating a cited memory that belonged to Mum. The update response now uses the memory text to preserve person-owned size subjects, e.g. `Mum's shoe size is now 39`.
- Some privacy/security comments and onboarding/backup copy still read stronger than the current implementation. They now describe current local storage, local deterministic recall, App Lock as a UI gate, and backup recovery limitations more carefully.

## Deferred UI Automation

No XCUITest target was added in this pass. A future UI automation pass can either:

1. add a project-managed XCUITest target through Xcode/scaffolding, then use the identifiers above, or
2. continue using XcodeBuildMCP semantic snapshots and element refs for lightweight smoke checks.

The current `ui` script mode is a smoke hook, not a full replacement for XCUITest assertions.

## Physical-Device Validation Still Required

- Real Face ID, Touch ID, and device passcode fallback.
- Cancelled and failed hardware authentication prompts.
- App switcher snapshot privacy and background/force-close behavior on real hardware.
- Locked-device file protection.
- Microphone recording and Apple Speech recognition reliability.
- Camera capture, photo library permissions, and OCR quality.
- iCloud backup/restore with a signed-in account.
- Notification permission behavior if future active notification features are enabled.
