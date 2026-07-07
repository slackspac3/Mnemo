# App Lock Physical Device Checklist - 2026-07-07

Use this checklist on a physical iPhone before App Store submission. Simulator validation is useful for build flow only; it does not prove real Face ID, Touch ID, passcode fallback, locked-device file protection, or iCloud behavior.

## Build

- Build commit:
- Device model:
- iOS version:
- Tester:
- Date:

## Test Cases

| Case | Expected | Result | Notes |
| --- | --- | --- | --- |
| App Lock off | Mnemo opens normally after onboarding with no authentication prompt. |  |  |
| Enable App Lock | Settings asks for Face ID, Touch ID, or passcode before enabling. |  |  |
| Successful Face ID unlock | Reopening Mnemo shows the lock screen and unlocks after successful Face ID. |  |  |
| Cancel auth prompt | Mnemo stays locked, shows a friendly retry message, and does not expose memories. |  |  |
| Failed Face ID then passcode | Device passcode fallback unlocks Mnemo through the system prompt. |  |  |
| Background and reopen | Mnemo locks after backgrounding and requires authentication on return. |  |  |
| App switcher privacy | Memories are not readable in the app switcher snapshot after backgrounding. |  |  |
| Force close and reopen | Mnemo starts locked when App Lock is enabled and onboarding is complete. |  |  |
| Disable App Lock | Settings asks for authentication before turning App Lock off. |  |  |
| Authentication unavailable after enable | If Face ID / Touch ID / passcode becomes unavailable, Mnemo avoids lockout and Settings clearly explains the state. |  |  |
| Delete All Data while locked | Delete All Data still returns to onboarding with App Lock off after the user unlocks and confirms deletion. |  |  |
| Delete All Data | Delete All Data removes memories/settings and returns to onboarding with App Lock off. |  |  |
| No biometric data stored | Confirm no Mnemo UI or storage asks for or stores biometric templates, passcodes, or account credentials. |  |  |
| No account required | Mnemo works without sign-up, login, email/password, Apple Sign In, OAuth, or backend identity. |  |  |

## Notes

- App Lock is a local UI access gate using Apple LocalAuthentication.
- App Lock does not replace file protection. Verify locked-device file protection separately in the pre-submission checklist.
- Optional iCloud backup still uses the user's signed-in iCloud account; Mnemo does not operate an account server.
