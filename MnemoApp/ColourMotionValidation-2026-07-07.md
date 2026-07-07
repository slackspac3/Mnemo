# Colour Motion Validation - 2026-07-07

Build context: local working tree after `f61d1fc37a4ae3280fa573e41f27e7c5f12b8325`.

Simulator used: iPhone 17 Pro, iOS 26.4, UDID `8F8259E7-F4C0-472A-833D-CD9BCD443425`.

## Summary

This pass tightened the Mnemonic Thread / Ink and Sage visual system, added semantic colour roles, applied them across high-traffic app surfaces, and added restrained Reduce Motion-aware press/transition feedback. It did not change product behavior or add new features.

## Palette and Role Changes

- Added explicit semantic roles for grouped/elevated backgrounds, surfaces, text, accent states, borders, source cards, memory cards, app lock, and private badges.
- Replaced fixed pale status colours with adaptive `successSoft`, `warningSoft`, and `destructiveSoft`.
- Preserved legacy aliases so existing views continue to compile while newer screens move to semantic roles.
- Source cards now use a dedicated sage-soft evidence treatment.
- Memory cards and detail cards now use a shared card surface and subtle border.

## Validation Table

| Screen / Component | Colour consistency | Motion applied | Reduce Motion handling | Light mode | Dark mode | Outcome | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Splash | Uses grouped background and brand mark roles. | None added. | Not applicable. | Screenshot/build reviewed. | Source-audited. | Pass | No decorative animation. |
| Onboarding | Uses grouped background, memory-card surfaces, warning soft surface, brand mark. | Page/progress animation remains subtle. | Progress/page animation falls back to fade. | Source-audited. | Source-audited. | Pass | Copy unchanged and honest. |
| Chat landing | Primary write action uses sage; secondary capture cards use elevated surfaces. | Press feedback on custom actions. | Press style removes scale and uses opacity. | Screenshot reviewed. | Screenshot reviewed. | Pass | Status capture hues retained as secondary affordances. |
| Text capture | Input, review card, buttons, and disabled states use semantic surfaces/tokens. | Press feedback on custom actions. | Press style handles Reduce Motion. | Source-audited. | Source-audited. | Pass | Raw confidence percentages remain removed from prior pass. |
| Browse cards | Memory cards use `memoryCardSurface` and `memoryCardBorder`. | Press feedback on cards and chips. | Press style handles Reduce Motion. | Source-audited. | Source-audited. | Pass | Layout unchanged. |
| Chat bubbles | User bubble uses accent; assistant bubble uses elevated surface. | Message insertion transition. | Transition falls back to opacity. | Simulator build/run reviewed. | Source-audited. | Pass | Recall behavior unchanged. |
| Source cards | Primary source card uses source-card surface/border/accent; secondary cards are quieter. | Source section fades in; cards have press feedback. | Fade/press opacity fallback. | Source-audited. | Source-audited. | Pass | Trust evidence is visually clearer without extra noise. |
| Memory Detail | Summary, metadata, original capture, archive, and delete surfaces use semantic roles. | Press feedback on archive/delete. | Press style handles Reduce Motion. | Source-audited. | Source-audited. | Pass | Archive/delete behavior unchanged. |
| Settings | Rows use elevated list surfaces; inactive Sense labels use disabled surface. | Native list behavior only. | Not applicable. | Source-audited. | Source-audited. | Pass | Settings copy remains no-account/local-first. |
| App Lock | Uses app-lock background/surface and tokenized foregrounds. | Unlock button press feedback; root lock state fade. | Root animation and press style respect Reduce Motion. | Source-audited. | Source-audited. | Pass | Real Face ID/passcode validation remains physical-device-only. |
| Empty states | Browse and chat empty states use brand/source/memory roles consistently. | Press feedback on CTAs. | Press style handles Reduce Motion. | Screenshot reviewed. | Screenshot reviewed. | Pass | Empty states remain instructional. |
| Buttons | Primary, secondary, destructive, and disabled states use tokens. | `MnemoPressableButtonStyle` added. | Scale disabled when Reduce Motion is on. | Source-audited. | Source-audited. | Pass | No new dependency. |
| Badges | Source/private/Sense badges use semantic soft surfaces. | None added. | Not applicable. | Source-audited. | Source-audited. | Pass | Inactive Sense rows look inactive. |
| Destructive actions | Delete uses destructive text, soft background, and destructive border. | Press feedback on destructive button. | Press style handles Reduce Motion. | Source-audited. | Source-audited. | Pass | Confirmation copy unchanged. |
| Dark mode | System backgrounds plus Ink/Sage roles render as one app. | Same motion as light mode. | Same Reduce Motion behavior. | N/A | XcodeBuildMCP dark screenshot reviewed. | Pass | Dark landing cards and text remained readable. |
| Dynamic Type | System typography retained; no custom fonts added. | No text-size-dependent animation. | Motion independent of text size. | Source-audited. | Source-audited. | Partial | Full large accessibility-size inspection remains pending. |
| Reduce Motion | Motion is limited to state changes and press feedback. | No decorative looping added. | Button scale removed; root/message/menu animations fade. | Source-audited. | Source-audited. | Pass | Existing voice recording waveform already respected Reduce Motion. |

## Animations Added

| Animation | Purpose | Decorative? | Reduce Motion handling |
| --- | --- | --- | --- |
| Press feedback for custom buttons/cards | Confirms tap state on controls that use custom styling. | No | Scale is disabled; opacity still changes subtly. |
| Message insertion move/fade | Clarifies new chat content arrival. | No | Uses opacity-only transition. |
| Source-card fade/press | Makes source evidence appear as attached to an answer. | No | Fade/opacity only. |
| Root lock/unlock fade | Clarifies app state change without exposing content. | No | Uses fade. |
| Capture menu spring/fade | Clarifies the floating capture menu opening/closing. | No | Uses fade-only transition. |

No looping decorative animations, sparkles, heavy transitions, Lottie, Rive, or external animation frameworks were added.

## Commands Run

```sh
swift test --quiet # in MnemoUI
xcodebuildmcp build_run_sim # workspace MnemoApp/Mnemo.xcworkspace, scheme Mnemo, iPhone 17 Pro simulator
xcodebuildmcp screenshot # light mode
xcodebuildmcp simulator-management set-appearance --simulator-id 8F8259E7-F4C0-472A-833D-CD9BCD443425 --mode dark
xcodebuildmcp screenshot # dark mode
xcodebuildmcp simulator-management set-appearance --simulator-id 8F8259E7-F4C0-472A-833D-CD9BCD443425 --mode light
Scripts/run_local_checks.sh fast
Scripts/run_local_checks.sh efficiency
MNEMO_SIMULATOR_ID=8F8259E7-F4C0-472A-833D-CD9BCD443425 Scripts/run_local_checks.sh ui
```

Results:

- `MnemoUI` package tests: passed.
- XcodeBuildMCP simulator build/run: passed, zero reported diagnostics.
- Light/dark simulator screenshots: passed visual inspection of the chat landing.
- `Scripts/run_local_checks.sh fast`: passed across all Swift packages and `git diff --check`.
- `Scripts/run_local_checks.sh efficiency`: passed. Recall over 1,000 synthetic memories averaged about 261 ms in this run; vector search over 1,000 averaged about 5.8 ms.
- `Scripts/run_local_checks.sh ui`: passed. Simulator build/run succeeded with zero diagnostics and the runtime snapshot exposed the polished chat landing actions and accessibility identifiers.

## Known Remaining Design Debt

- Full large Dynamic Type manual inspection is still pending.
- Physical-device validation remains required for real Face ID/Touch ID/passcode prompts, microphone, Speech recognition, camera, OCR quality, iCloud backup/restore, notifications, locked-device file protection, and app-switcher privacy.
- AppIcon production asset replacement remains a separate export/visual-QA task.
- Some lower-risk legacy aliases remain in `DS.Colours` for compatibility, but high-traffic views now use explicit semantic roles.
