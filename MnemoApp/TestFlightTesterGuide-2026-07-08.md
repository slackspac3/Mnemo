# TestFlight Tester Guide - 2026-07-08

## First Run
1. Install Mnemo from TestFlight on an iPhone.
2. Complete onboarding.
3. Notice that no account, email, password, or test credential is required.

## Core Memory Loop
1. Tap **Write memory**.
2. Save a simple memory, for example: `Mum wears size 38 shoes.`
3. Open Chat and ask: `What size does mum wear?`
4. Check whether Mnemo answers correctly.
5. Tap the source card and confirm it opens the saved memory.
6. Open Browse and confirm the memory appears there.

## Try More Real Memories
Try 10 to 20 realistic memories across:
- People and preferences.
- Shopping or things you forget.
- Travel details.
- Sizes.
- Dates and deadlines.
- Decisions.
- Reference details that are safe to test.

Avoid entering real passwords, bank details, passport numbers, or highly sensitive credentials during this early TestFlight.

## Archive and Delete
1. Save a disposable memory.
2. Ask about it in Chat and open its source card.
3. Archive it and confirm it no longer appears in Browse or recall.
4. Save another disposable memory.
5. Delete it permanently and confirm it no longer appears in Browse or recall.

## Voice, Photo, OCR, and App Lock
On a physical iPhone:
1. Try voice capture and confirm the transcript can be saved and recalled.
2. Try camera or photo OCR with readable text.
3. Enable App Lock in Settings and confirm the device authentication prompt appears.
4. Try Delete All Data and confirm the app returns to a clean first-run state.

## Feedback Questions
- Was the app clear on first launch?
- Did you understand what Mnemo stores and where it stores it?
- Did you trust the answer?
- Did the source card help you trust or correct the answer?
- What would you actually save in Mnemo?
- What felt risky or unclear?
- What failed or felt slow?
- Would you use this weekly?
- What would you expect to pay for if Mnemo became a paid product later?

## Known Limits In This Build
- No account or sync identity exists.
- No production Apple Foundation Models, MLX inference, or cloud LLM path is active.
- iCloud backup is optional and uses the user's own iCloud account.
- Restore on a new or replacement iPhone is not available in this build.
- Real microphone, camera, OCR, Face ID, Touch ID, passcode fallback, and iCloud behaviour require physical-device validation.
