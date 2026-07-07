# Brand Identity Direction - 2026-07-07

Build context: local working tree after `6304302088cde202165e7205d1136608305a1630`.

Pass: Mnemo Brand Identity and Visual System Pass.

## Summary

Mnemo should feel like a private memory layer, not a generic AI chat app. This pass chooses a calm **Mnemonic Thread** direction and implements the safest parts in the app: a reusable in-app mark, an ink-and-indigo semantic palette, and updated source/privacy surfaces.

Production AppIcon export is intentionally left as a follow-up. The source direction is documented and a simple vector construction file is included for handoff.

| Area | Decision | Rationale | Implementation |
| --- | --- | --- | --- |
| Brand personality | Private, calm, personal, premium, local-first. | The product promise depends on trust, not novelty. The UI should feel closer to Apple Notes/Journal/Reminders than an AI assistant demo. | Copy continues to say no account, local memory, source-backed recall, and user control. |
| Logo direction | Direction A: Mnemonic Thread. | A continuous folded line suggests memory, continuity, and recall without using brains, chat bubbles, robots, or lock/vault clichés. | Added `MnemoLogoMark` in `MnemoUI` and used it in splash, onboarding, App Lock, Settings, Chat landing, and Browse empty state. |
| App icon direction | Rounded ink tile with a white mnemonic-thread mark; optional indigo variant for internal marks. | Works at small size, survives iOS icon masking, and avoids tiny details. | Added `MnemoApp/Design/MnemoLogoMark.svg` and `AppIconNotes-2026-07-07.md`. AppIcon asset set was not updated in this pass. |
| Colour palette | Ink and Indigo. Primary ink `#0D1321`; accent indigo `#3730A3` in light mode and `#6366F1` in dark mode; soft indigo surfaces through semantic opacity. | Matches the current semantic token system and keeps one disciplined action colour. | `DS.Colours.brandSage` remains as a compatibility alias that maps to `accent`; docs now describe the real palette as Ink and Indigo. |
| Typography approach | System typography only, with existing Dynamic Type-backed DS tokens. | Native, accessible, and App Store-appropriate. | No custom fonts added. Existing `DS.Typography` remains the source of truth. |
| Source card treatment | Source cards use dedicated semantic source-card surface and border tokens. | Source cards are trust evidence and should feel deliberate without becoming decorative. | `DS.ComponentTokens.SourceCard` now maps to `sourceCardSurface` and `sourceCardBorder`. |
| Privacy/security visual language | Identity mark plus calm ink/indigo, not vaults, cyber styling, or fear-based security language. | Mnemo should feel protected by the device and user control, not paranoid. | App Lock uses the Mnemo mark and copy remains LocalAuthentication/no-account accurate. |
| What we avoided | Neon AI gradients, sparkle overload, brain/robot/chat-bubble logos, dark cyber-security styling, skeuomorphic vaults, huge generated icon sets. | These would weaken Mnemo’s private-memory positioning and risk looking generic or gimmicky. | No new external assets, fonts, dependencies, account flows, or AI capability claims were added. |

## Chosen Palette

| Token | Value / Behaviour | Use |
| --- | --- | --- |
| `primary` | Ink `#0D1321` | Brand mark fill, calm title emphasis. |
| `accent` | Indigo `#3730A3` / `#6366F1` dark mode | Primary actions, tabs, source affordances. |
| `accentPressed` | Pressed indigo | Pressed/active brand state. |
| `accentSoft` | Indigo at low opacity | Private badges, icon wells, quiet emphasis. |
| `backgroundPrimary` | System grouped background | App background. |
| `surfacePrimary` | System secondary grouped background | Cards and rows. |
| `surfaceSecondary` | System tertiary grouped background | Secondary controls and fields. |
| `sourceCardSurface` | Semantic surface | Source memory cards. |
| `sourceCardBorder` | Indigo border | Trust affordance without heavy decoration. |
| `appLockSurface` | Semantic surface | Lock screen card. |
| `privateBadgeSurface` | Soft indigo | Private/local badges and logo variants. |

## App Store Readiness Notes

- The in-app mark is suitable for screenshots and TestFlight walkthroughs.
- AppIcon export remains a design-production task because icon assets should be reviewed at 1024 px, small homescreen size, light/dark wallpapers, and rounded-square masking before replacing the production icon set.
- The current mark can be exported from `MnemoApp/Design/MnemoLogoMark.svg` as the basis for the AppIcon source.
