# Deep Simulator QA - 2026-07-07

## Build Under Test

- Commit: base `67c0b1fe38a39194ad0c4181f685def71fd4683d` plus QA fixes in this pass.
- Simulator: iPhone 17 Pro, `8F8259E7-F4C0-472A-833D-CD9BCD443425`.
- iOS version: iOS 26.x simulator runtime.
- Xcode/XcodeBuildMCP environment: `MnemoApp/Mnemo.xcworkspace`, scheme `Mnemo`, Debug simulator build via XcodeBuildMCP CLI.
- Test date: 2026-07-07.

## Summary

| Area | Outcome | Notes |
| --- | --- | --- |
| Launch/onboarding | Pass | Four safe onboarding screens were exercised in simulator. No seeded capture or credential-shaped prompt appeared. |
| Text capture | Pass | Empty input had no save target. Normal memory was reviewed, saved, and returned to Chat. |
| Browse | Pass with source-audit note | Saved memory appeared in Browse. Browse detail route is real `MemoryDetailView`; semantic tap on Browse cell did not navigate during one run, but source-card tap-through validated detail presentation. |
| Chat recall | Pass | `What size does mum wear?` returned the correct answer and cited the saved memory. |
| Source cards | Pass | Source card appeared only on cited answer and opened the correct `MemoryDetailView`. |
| Memory detail | Pass | Real detail sheet showed summary, metadata, original capture, Archive, and Delete Permanently. |
| Archive/delete | Pass / partial | Archive from source-card detail hid the memory from active recall. Permanent delete path is source-audited and package-tested. |
| Delete All Data | Pass | Destructive confirmation appeared and completion returned the app to onboarding. |
| App Lock UI/state | Source-audited | Settings row/copy visible. Real LocalAuthentication is physical-device-only. |
| Privacy shield | Source-audited | `AppLockView` takes precedence; privacy shield shows on inactive/background when App Lock is enabled. Hardware app-switcher timing remains pending. |
| Backup UI/copy | Pass / source-audited | Copy states user iCloud, no Mnemo backup server, and local Keychain restore limitation. Real CloudKit backup not run. |
| Settings | Pass after fix | “On-Device Only” is now static local-only copy, not a toggle for unavailable Cloud Assist. |
| Accessibility | Partial | Source-audited identifiers and labels. Large Dynamic Type and VoiceOver ordering still need hands-on device/simulator accessibility session. |
| Light/dark mode | Pass smoke | Light mode exercised through main flows; dark-mode semantic snapshot passed on Chat recall/source-card screen. |
| Dynamic Type | Source-audited | Typography uses semantic styles. Some badges may still need large-text hands-on validation. |
| Reduce Motion | Source-audited | Main root and component motion paths use reduced-motion branches; no full simulator Reduce Motion run was performed. |
| Performance | Pass | Existing efficiency baseline passed for 30, 100, 500, and 1,000 synthetic memories. |
| Physical-device-only items | Pending | Not validated on simulator. |

## Validation Commands

| Command | Result | Notes |
| --- | --- | --- |
| `Scripts/run_local_checks.sh fast` | Pass | MnemoCore, MnemoSecurity, MnemoMemory, MnemoCapture, MnemoIntelligence, MnemoSync, and MnemoUI package tests passed; script `git diff --check` passed. |
| `Scripts/run_local_checks.sh efficiency` | Pass | MnemoMemory recall/vector efficiency baseline passed at 30, 100, 500, and 1,000 synthetic memories. |
| `MNEMO_SIMULATOR_ID=8F8259E7-F4C0-472A-833D-CD9BCD443425 Scripts/run_local_checks.sh ui` | Pass | XcodeBuildMCP simulator build/run succeeded with zero diagnostics; semantic snapshot showed consolidated Chat/Browse UI. |
| `MNEMO_SIMULATOR_ID=8F8259E7-F4C0-472A-833D-CD9BCD443425 Scripts/run_local_checks.sh app` | Pass | XcodeBuildMCP simulator build/run succeeded with zero diagnostics. |
| `git diff --check` | Pass | No whitespace errors. |

## Detailed Test Matrix

| ID | Flow | Method | Expected | Actual | Outcome | Bug / Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| L01 | Preflight branch/commit | Git/source | Local `main` equals `origin/main` at expected commit and worktree clean before QA | Confirmed `main`, `67c0b1f`, clean tree, origin/main same | Pass |  |
| L02 | Background refresh removed | Source search | No `BackgroundTasks`, `.backgroundTask`, `BGAppRefresh` active code | Only consolidation report mentions removed feature | Pass |  |
| L03 | Threads hidden | Source + simulator | No Threads tab visible | Tab snapshot showed only Chat and Browse; source has no `.threads` tab case | Pass | `ThreadsView` file remains unreachable. |
| O01 | First onboarding screen | Simulator | Private-memory copy, no sensitive prompt | “Your private memory layer”; no account copy visible | Pass |  |
| O02 | Recall onboarding screen | Simulator | Source-backed recall, no cloud overclaim | “Ask what you saved”; “No cloud AI in this build” | Pass |  |
| O03 | Protection onboarding screen | Simulator | App Lock copy, no account wording | Face ID/Touch ID/passcode copy and no account recovery copy visible | Pass | Real auth pending. |
| O04 | Final onboarding screen | Simulator | CTA enters main app; no memory written | “Start Mnemo” opened Chat landing | Pass |  |
| C01 | Empty text capture | Simulator | Whitespace/empty save blocked | Text sheet opened with input only; no Save target until text entered | Pass |  |
| C02 | Text capture review | Simulator | Review card shown with safe copy | `Mum wears size 38 shoes.` produced `Review suggested` and Save Memory | Pass |  |
| C03 | Save memory | Simulator | Memory saved once and app returns to Chat | Save returned to Chat and Ask Mnemo examples appeared | Pass |  |
| B01 | Browse populated | Simulator | Saved memory appears | Browse showed `Mum wears size 38 shoes.` with Text/date metadata | Pass |  |
| B02 | Browse detail route | Simulator/source | Memory cell opens real detail | Direct Browse semantic tap did not navigate during one run; source uses real sheet and source-card tap-through verified detail | Partial | Retest Browse cell tap on physical/simulator manually. |
| R01 | Chat recall answer | Simulator | Correct answer with source | Answer included size `38` and source card | Pass | Fixed awkward “Your Mum’s…” grammar. |
| R02 | Source card tap-through | Simulator | Opens correct memory detail | Source card opened `MemoryDetailView` for Mum memory | Pass |  |
| R03 | No-match after archive | Simulator | Archived memory not recalled | Same query returned “I do not have any saved memories yet...” | Pass | Prior historical source card remains in transcript, but no new source card was added. |
| U01 | Last-cited update after archive | Source audit/fix | Archived cited memories are not mutated | `ChatViewModel` now filters archived cited memories and returns a safe no-active-source response | Pass | Add deeper UI test later. |
| A01 | Archive confirmation | Simulator | Copy differentiates archive from delete | Confirmation says archive hides from Browse/Chat recall but keeps local store | Pass |  |
| A02 | Archive index cleanup | Simulator + package tests | Archived memory excluded from recall/vector search | Simulator recall excluded it; package tests cover archive unindex | Pass |  |
| D01 | Delete All Data confirmation | Simulator | Explicit irreversible destructive copy | Dialog said all memories, threads, and settings are permanently deleted | Pass |  |
| D02 | Delete All Data completion | Simulator | App returns to onboarding and state reset | Confirming returned to onboarding screen | Pass | Fixed vector wipe order before final validation. |
| S01 | Settings privacy row | Simulator/source | No account; local-only copy honest | Settings showed no-account copy; local-only row became static after fix | Pass |  |
| S02 | App Lock row | Simulator/source | Device auth copy, no account claim | Row says Face ID, Touch ID or device passcode | Pass | Real prompts pending. |
| S03 | Inactive Sense rows | Simulator/source | Coming-later, not active toggles | Memory Moments, Pattern Insights, Thread Suggestions shown as Coming later | Pass | Consider hiding entire section before App Store screenshots if still visually noisy. |
| BK01 | Backup copy | Source audit | User iCloud, no Mnemo server, local key limitation | UI/docs say private iCloud, no backup server, local Keychain key required | Pass | Real iCloud pending. |
| AL01 | Privacy shield | Source audit | Covers content on inactive/background when App Lock enabled | `AppRootView` routes `AppLockView` first, then `PrivacyShieldView`; `AppState` shows shield on inactive/background | Pass source | Hardware app-switcher timing pending. |
| V01 | Placeholder search | Source search | No user-visible Phase 9 placeholder route | No app-flow placeholder route found | Pass |  |
| V02 | Dark mode smoke | XcodeBuildMCP appearance + snapshot | Recalled chat/source card remains readable/accessibility visible | Dark semantic snapshot preserved message/source text | Pass smoke | Visual screenshot not committed. |
| P01 | Efficiency baseline | Package tests | Existing recall/vector thresholds pass | 30/100/500/1000-memory baselines passed | Pass | See command results. |

## Bugs Found

| Bug | Severity | Evidence | Fix made | Retest |
| --- | --- | --- | --- | --- |
| Settings exposed `On-Device Only` as a switch even though Cloud Assist is unavailable. | Medium | Simulator Settings showed a tappable On-Device Only switch. | Replaced with static local-only row and enforced local-only persisted state on Settings load. | Rebuilt app; Settings snapshot shows static “On-Device Only, Capture and recall stay local...” text and no On-Device Only switch. |
| Delete All Data wiped vectors before SwiftData deletion/save. | Medium | Source audit of `SettingsView.deleteAllData`. | Reordered flow to delete/save SwiftData first, then wipe vector index, preserving canonical data if save fails. | Package checks, app build/run, and simulator smoke passed. |
| Update requests could mutate archived cited memories. | Medium | Source audit: update flow fetched cited memories by ID without filtering archived records. | Filtered archived memories and return a safe no-active-source response when none remain. | Package checks and app build/run passed; deeper UI update sequence remains a future regression candidate. |
| Size answer copy said “Your Mum’s shoe size...” | Low | Simulator Chat recall snapshot showed the awkward prefix. | Added person-owned subject formatting in `RecallEngine` plus regression test. | Rebuilt app; simulator recall says “Mum’s shoe size is 38.” |

## Physical-Device Pending

- Real Face ID, Touch ID, device passcode fallback, cancelled and failed biometric prompts.
- App-switcher snapshot timing on real hardware.
- Locked-device file protection.
- Microphone permission, recording, and Apple Speech recognition reliability.
- Live camera capture.
- Photo library permission behavior on hardware.
- OCR quality from real camera/photos.
- iCloud backup/restore on a signed-in account.
- Notification permission behavior if future notification features are enabled.

## Notes

- No XCUITest target, CI pipeline, or new test infrastructure was added.
- No sign-up, Apple Sign In, backend auth, Foundation Models, MLX, cloud LLM, autonomous behavior, or external dependency was added.
- XcodeBuildMCP had one transient `wait-for-ui` / `touch` daemon auto-start failure; direct snapshot/tap/build commands continued to work and app behavior was not implicated.
