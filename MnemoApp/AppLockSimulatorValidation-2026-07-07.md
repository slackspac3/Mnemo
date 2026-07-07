# App Lock Simulator Validation - 2026-07-07

## Build Tested

| Item | Value |
| --- | --- |
| Base commit | `6fecc7638f8611ec78ca504cd79642b552038b31` (`Add local App Lock`) |
| Validation state | Working tree with App Lock automated/simulator validation fixes from this pass |
| Simulator | iPhone 17 Pro, iOS 26.4, where available |
| Physical device | Not available in this run |
| Account/sign-in | Not implemented; no Mnemo account is required |

## Scope Boundary

This pass validates App Lock policy logic, Settings copy, stored setting persistence, app build/run, and source-auditable state handling before physical-device testing. It does not validate real Face ID, Touch ID, passcode fallback, hardware prompt cancellation, locked-device file protection, microphone, camera, OCR, iCloud, or notifications.

## Flow Results

| Flow | Environment | Expected | Actual | Outcome | Notes |
| --- | --- | --- | --- | --- | --- |
| App Lock off launch | Simulator / source audit | App opens normally after onboarding | `AppRootView` only shows `AppLockView` when `appLockEnabled && isAppLocked`; default `UserModel.appLockEnabled` is false and tested | Pass | Package test confirms default is off. App build/run completed in simulator. |
| Settings Security section visible | Source audit / simulator build | App Lock toggle appears after onboarding | Settings has a `Security` section with `Require App Lock to Open Mnemo` and supporting device-auth copy | Pass | The label avoids Face ID-only wording because LocalAuthentication may use Touch ID or device passcode. |
| Enable App Lock attempt | Source audit / unit test | Uses LocalAuthentication simulator behavior or documents limitation | Toggle decision requires authentication when device authentication is available and blocks enabling when unavailable | Pass for policy; physical pending | Real system prompt behavior remains physical-device validation. |
| Lock screen visible when forced locked | Source audit / simulator build | Lock screen covers memories | `AppRootView` overlays `AppLockView` above `PlaceholderMainView` when runtime lock state is true | Source-audited | No DEBUG-only force-lock route was added; production behavior was not weakened for simulator convenience. |
| Unlock cancelled/fails | Unit test / source audit | Memories remain hidden | `unlockApp()` keeps `isAppLocked` true on false/throwing auth and shows an error message | Source-audited | Apple prompt cancellation/failure UI remains physical-device validation. |
| Background lock policy | Unit test | State becomes locked when enabled | `AppLockPolicy` tests cover enabled/onboarded launch lock, disabled/onboarding-incomplete no-op, nil background timestamp, zero grace, and grace-period threshold | Pass | App runtime currently uses zero-second grace after backgrounding. |
| Delete All Data reset | Source audit | App Lock clears and onboarding state returns | `SettingsView.deleteAllData()` deletes models, wipes vector store, saves, dismisses stale sheets, then calls `appState.resetAfterDeleteAllData()` | Source-audited | Destructive end-to-end pass remains pending on a disposable simulator/device. |
| No account required | Source audit | No sign-up/login UI appears | App Review notes, lock screen, and code paths do not introduce sign-up, login, Apple Sign In, OAuth, email/password, or backend identity | Pass | `AppLockView` explicitly says no Mnemo account is required. |
| Security copy | Source audit | No claim that App Lock encrypts data by itself | README and checklist state App Lock is a LocalAuthentication UI access gate, not account sign-in or replacement for file protection | Pass | App Review notes also state Mnemo does not receive/store biometrics, passcodes, account credentials, or backend identity data. |

## Automated Coverage Added

- `AppLockSettingsPolicy` in `MnemoSecurity` makes Settings toggle decisions testable without mocking Apple biometric prompts.
- `MnemoSecurityTests` now cover:
  - background lock no-op when App Lock is disabled or onboarding is incomplete,
  - lock behavior with no background timestamp,
  - immediate lock behavior with zero grace period,
  - Settings decisions for enabling, disabling, unavailable auth, stale disable, and unchanged values.
- `MnemoMemoryTests` now cover:
  - `UserModel` privacy/security flags, including `appLockEnabled`, persisting across model contexts,
  - legacy `UserModel` initializer keeping App Lock disabled,
  - decoded user payloads surviving persistence.

## Bugs Found And Fixed

- Settings copy said `Require Face ID to Open Mnemo` even though the implementation uses `LAContext` device-owner authentication, which may use Face ID, Touch ID, or device passcode. The row now says `Require App Lock to Open Mnemo`.
- The Face ID usage string implied authentication only happens when enabling App Lock. It now also covers unlock and turn-off flows and states Mnemo does not receive or store biometric data.
- Settings toggle persistence could mutate the in-memory `UserModel` before a failed save, allowing UI/runtime drift. The persistence helper now rolls back `appLockEnabled` and `updatedAt` if saving fails.
- Security docs/checklist now describe App Lock as a LocalAuthentication UI gate, not account sign-in or replacement for file protection.

## Source-Audited Risks

- App Lock fail-opens if device authentication becomes unavailable after the setting was previously enabled. That avoids lockout, but physical-device validation should confirm the Settings message and recovery behavior are acceptable.
- `.inactive` currently does not lock immediately. The app locks on `.background`; physical-device validation must confirm app-switcher/snapshot privacy timing is acceptable before submission.
- Delete All Data is source-audited and covered by broader local checks, but the actual destructive UI flow still needs one hands-on run on disposable simulator/device data.

## Physical-Device Validation Still Required

- Real Face ID unlock.
- Touch ID unlock on supported hardware.
- Device passcode fallback.
- Cancelled and failed system prompt behavior.
- Background and force-close behavior on real hardware.
- Delete All Data while App Lock is enabled on real hardware.
- Locked-device file protection.
- Microphone, camera, OCR, iCloud, and notification behavior.

## Result

Before physical-device testing, App Lock has package-level coverage for the deterministic decision logic, persisted setting state, and local-only copy boundaries. Simulator validation is limited to build/run and source-auditable UI state; real LocalAuthentication behavior remains explicitly pending.
