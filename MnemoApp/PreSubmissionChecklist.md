# Mnemo Pre-Submission Checklist

Complete every item before submitting to App Store Review.

## Legal and Accounts
- [ ] Apple Developer account converted to Think Act Management Consulting L.L.C (Organisation)
- [ ] D-U-N-S number confirmed for Think Act
- [ ] Trade licence renewed (expired 05/03/2026 - confirm renewal)
- [ ] Privacy policy live at a public URL
- [ ] Support contact page live at a public URL
- [ ] Terms of service live at a public URL

## App Store Connect Setup
- [ ] App record created in App Store Connect for com.thinkact.mnemo
- [ ] App name: Mnemo
- [ ] Subtitle: Your private memory companion
- [ ] Category: Primary - Productivity, Secondary - Utilities
- [ ] Age rating completed (likely 4+)
- [ ] Privacy policy URL entered in App Store Connect
- [ ] Support URL entered in App Store Connect

## Privacy Nutrition Label (App Store Connect -> App Privacy)
- [ ] User Content declared: typed text, stored locally, not linked to user, app functionality only
- [ ] Product Interaction declared: usage patterns, on-device only, not linked to user, app functionality
- [ ] No other data types collected
- [ ] If cloud fallback enabled: User Content also declared for cloud processing (not linked to user)

## Build Quality
- [ ] Build succeeds with zero errors in Xcode 26
- [ ] No warnings in release build (treat warnings as errors for submission)
- [ ] Tested on physical iPhone (iOS 18+)
- [ ] Tested on iPhone 17 Pro Max (Tier 1 - full Foundation Models)
- [ ] Voice capture tested on physical device (simulator cannot test microphone)
- [ ] Image capture tested on physical device (simulator has no camera)
- [ ] iCloud backup tested (requires signed-in iCloud account)
- [ ] Delete All Data flow tested and confirmed complete wipe
- [ ] Onboarding AI consent screen confirmed: names Anthropic as cloud provider

## Security
- [ ] Secure Enclave key generation tested on physical device
- [ ] NSFileProtectionComplete verified on physical device (inaccessible when locked)
- [ ] Biometric app lock tested (Face ID on iPhone 17 Pro Max)
- [ ] No API keys or secrets in the binary (verified - proxy holds Anthropic key)
- [ ] No cleartext HTTP exceptions in Info.plist

## Compliance
- [ ] PrivacyInfo.xcprivacy added to app target
- [ ] All permission usage strings present in Info.plist
- [ ] No UIBackgroundModes audio declared (confirmed)
- [ ] AppReviewNotes.txt prepared for App Review Notes field
- [ ] OWASP Mobile Top 10 self-assessment completed

## App Store Assets (prepare separately)
- [ ] App icon 1024x1024 PNG (no alpha, no rounded corners - Apple applies mask)
- [ ] Screenshots for iPhone 6.9" (iPhone 17 Pro Max): minimum 3, maximum 10
- [ ] Screenshots for iPhone 6.1": required if different from 6.9"
- [ ] App preview video (optional but recommended)
- [ ] Description written (see pitch document for language)
- [ ] Keywords (100 character limit): memory, recall, private, AI, notes, capture, voice, reminder, context, personal
- [ ] What's New text for version 1.0 (can be brief: "First release.")

## Final Steps
- [ ] Archive built in Xcode (Product -> Archive)
- [ ] Validated archive in Xcode Organiser (no issues)
- [ ] Uploaded to App Store Connect via Xcode or Transporter
- [ ] App Review Notes pasted from AppReviewNotes.txt
- [ ] Submit for Review
