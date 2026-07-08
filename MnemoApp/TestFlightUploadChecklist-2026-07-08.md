# TestFlight Upload Checklist - 2026-07-08

## Account and App Record
- [ ] Apple Developer account/team ready for Think Act Management Consulting L.L.C.
- [ ] App Store Connect app record created for `com.thinkact.mnemo`.
- [ ] Bundle ID matches the Xcode project and App Store Connect record.
- [ ] iCloud container and entitlements are aligned before exposing backup in TestFlight.
- [ ] Signing team and provisioning profiles are valid for archive upload.

## Version and Device Family
- [ ] `MARKETING_VERSION = 1.0`.
- [ ] `CURRENT_PROJECT_VERSION = 1` if build 1 has never been uploaded.
- [ ] Increment `CURRENT_PROJECT_VERSION` to 2 or higher if build 1 already exists in App Store Connect.
- [ ] `TARGETED_DEVICE_FAMILY = 1` for iPhone-only V1.
- [ ] Do not enable iPad until a dedicated iPad QA pass exists.

## Build and Archive
- [ ] Run local fast checks.
- [ ] Run local efficiency checks.
- [ ] Run simulator UI/app smoke checks where available.
- [ ] Run a Release archive in Xcode.
- [ ] Validate archive in Xcode Organizer.
- [ ] Upload archive to App Store Connect through Xcode or Transporter.

## Export Compliance and Privacy
- [ ] Complete export compliance in App Store Connect.
- [ ] Confirm Privacy Nutrition Label includes user content stored for app functionality.
- [ ] If iCloud Backup is enabled, disclose optional encrypted iCloud backup storage.
- [ ] Confirm Mnemo does not operate a backup server.
- [ ] Confirm no cloud LLM provider is configured in this build.
- [ ] Confirm no StoreKit, paywall, subscription, or monetisation UI is present.

## Beta Review Info
- [ ] Paste or adapt `TestFlightReviewNotes-2026-07-08.md`.
- [ ] State no account or test credentials are required.
- [ ] State contextual permission usage.
- [ ] State Foundation Models and MLX are not production paths in this build.
- [ ] State restore on a new or replacement iPhone is not available in this build.

## Internal Test Group
- [ ] Create internal tester group.
- [ ] Add only intended internal testers.
- [ ] Share `TestFlightTesterGuide-2026-07-08.md`.
- [ ] Ask testers not to enter real passwords, passport numbers, banking details, or other highly sensitive credentials during early validation.

## External TestFlight Later
- [ ] Complete physical-device validation first.
- [ ] Publish privacy policy URL.
- [ ] Confirm support URL.
- [ ] Re-check App Review notes and screenshots.
- [ ] Decide whether optional backup should remain visible for external testing.
