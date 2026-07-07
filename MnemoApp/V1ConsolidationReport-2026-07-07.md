# V1 Consolidation Report - 2026-07-07

Scope: V1 Consolidation and Launch Scope Hardening.

This pass reduces launch scope before physical-device validation. It removes inactive top-level surfaces, shortens onboarding, removes background refresh, adds an App Lock privacy shield for app-switcher protection, and tightens backup and palette language. It does not add new product features.

| Area | Issue | Decision | Change made | Validation |
| --- | --- | --- | --- | --- |
| Background refresh | App refresh was registered and scheduled before Memory Moments had a V1 user-facing value or Info.plist configuration. | Cut from V1. | Removed `BackgroundTasks`, `.backgroundTask`, refresh identifier, scheduling, and refresh handler from `MnemoApp`. | Source search plus app build. Background refresh is no longer registered. |
| Onboarding | Seeded capture steps asked for preference/list/credential-shaped data and wrote real memories during first run. | Shorten and de-risk. | Onboarding is now four informational screens: private memory layer, ask what you saved, protected by your device, start with one memory. It no longer writes memories or asks for credential-shaped data. | Source search plus simulator smoke. |
| Threads | Threads was a primary tab while automatic thread suggestions are not active. | Hide from main V1 navigation. | Removed Threads from `MainTabView` and removed the `tab.threads` smoke expectation. Settings may still describe inactive Sense features as coming later. | Source search plus simulator smoke. |
| Placeholder routes | Developer placeholder routes and wrappers could appear unfinished if reached. | Remove user-reachable placeholders. | Removed placeholder sheet routes and placeholder wrapper views. `AppRootView` now routes directly to `OnboardingView` and `MainTabView`. | Source search and app build. |
| App-switcher privacy | App Lock locked on background but did not show a separate shield while inactive. | Add a simple privacy shield without changing authentication behavior. | `AppState` now shows a `PrivacyShieldView` when App Lock is enabled and the scene becomes inactive/background. `AppLockView` still takes precedence when locked. | Source audit and simulator build. Physical-device snapshot timing remains pending. |
| Insert/index consistency | New memories could be saved to SwiftData before vector indexing completed, leaving repair dependent on a later rebuild. | Add narrow repairability. | `insertAndIndex` now retries indexing once and attempts `rebuildIndex(in:)` if retry fails before surfacing the error. Existing rebuild tests cover repair of missing/stale vector rows. | `MnemoMemory` package tests and local checks. |
| Backup copy | Backup copy could be read as stronger lost-device recovery than the current Keychain-key design supports. | Keep backup available but make recovery limits explicit. | Backup UI, README, App Review notes, checklist, and physical checklist now state that iCloud is the user's account, Mnemo has no backup server, and restore requires this iPhone's local Keychain backup key. | Source audit and app build. |
| Design token truth | Docs said Ink and Sage while the active token system maps the legacy `brandSage` alias to indigo. | Rename docs, not palette. | Brand docs now describe the real palette as Ink and Indigo. The `brandSage` alias remains for compatibility and maps to `accent`. | Source audit. No UI palette redesign. |

## Physical-Device Items Still Pending

- Real Face ID, Touch ID, passcode fallback, cancelled/failed prompts, and force-close/background behavior.
- App-switcher snapshot privacy timing on real hardware.
- Locked-device file protection.
- Microphone capture and Apple Speech reliability.
- Camera, photo library permission prompts, and OCR quality.
- iCloud backup/restore on a signed-in account, including the local Keychain backup-key limitation.
- Notification behavior if any future notification feature is enabled.
