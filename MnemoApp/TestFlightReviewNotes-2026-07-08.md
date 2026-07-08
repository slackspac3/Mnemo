# TestFlight Review Notes - 2026-07-08

## Build
- Version: 1.0
- Build: 1
- Device family: iPhone only for first internal TestFlight
- Note: keep build 1 only if no App Store Connect upload has used it. Increment `CURRENT_PROJECT_VERSION` before upload if build 1 already exists in App Store Connect.

## App Purpose
Mnemo is a private memory companion for iPhone. Testers can save personal details, decisions, reminders, voice transcripts, and image OCR text, then ask Mnemo questions and see the saved memory used as the source.

## Account and Credentials
- No Mnemo account is required.
- No sign-up, sign-in, Apple Sign In, email/password, OAuth, backend identity, or test credentials are used.
- The app can be tested without iCloud. Optional iCloud Backup uses the tester's own signed-in iCloud account.

## What To Test
1. Complete onboarding.
2. Save one text memory from the main screen.
3. Ask about that memory in Chat.
4. Confirm the answer cites a source memory.
5. Tap the source card and confirm the correct memory opens.
6. Browse saved memories.
7. Archive and permanently delete disposable memories.
8. Try voice capture, image/photo OCR, optional App Lock, backup, restore, and Delete All Data on a physical iPhone.

## Permissions
Permissions are requested contextually:
- Microphone and Speech Recognition are requested for voice capture.
- Camera is requested for camera capture.
- Photo Library is requested for photo OCR.
- Face ID is requested only when App Lock is enabled or disabled.

## AI and Extraction Status
- Current recall is deterministic and local over saved memory text, SwiftData, and the local vector index.
- Apple Foundation Models and MLX model routes exist as architecture hooks only; this build does not ship production Foundation Models or MLX inference.
- No cloud LLM provider is configured, and no external LLM requests are made in this build.

## Backup Limitation
- Optional backup stores encrypted backup data in the user's own iCloud account.
- Mnemo does not operate a backup server.
- Restore currently requires this iPhone's local Keychain backup key.
- Restore on a new or replacement iPhone is not available in this build and should not be treated as lost-device recovery.

## App Lock Limitation
- App Lock uses Apple LocalAuthentication as a local UI access gate.
- Mnemo does not receive, store, or upload biometric data, biometric templates, device passcodes, or account credentials.
- App Lock is not account sign-in and is not a replacement for file protection.

## Known Hardware-Only Validation
These items must be tested on a physical iPhone and should not be inferred from simulator results:
- Face ID, Touch ID, and passcode fallback.
- Microphone recording and Apple Speech recognition reliability.
- Live camera capture and real photo-library permission behaviour.
- OCR quality from real photos and camera captures.
- iCloud backup and restore with a signed-in account.
- App-switcher snapshot privacy timing and locked-device file protection.

## Reviewer Steps
1. Launch Mnemo on an iPhone.
2. Complete the four-screen onboarding.
3. Tap **Write memory** and save: `Mum wears size 38 shoes.`
4. Ask: `What size does mum wear?`
5. Confirm the answer says `38` and shows a source card.
6. Tap the source card to open Memory Detail.
7. In Settings, review App Lock, Backup, and Delete All Data copy.
