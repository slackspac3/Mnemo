# Colour Usage Map - 2026-07-07

Build reviewed: `8efc0e6096f043b4d71bda0203dbcab8158d670f`

Palette direction remains **Mnemonic Thread / Ink and Sage**. This pass reduces non-semantic colour and keeps status colours for status.

| UI Element | Colour role to use | Current problem | Change |
| --- | --- | --- | --- |
| Primary CTA | `accent`, `textOnAccent` | Primary action is oversized but colour is correct. | Keep sage, reduce height and add chevron. |
| Secondary capture cards | `surfaceElevated`, `borderSubtle`, `accent` icons | Camera uses success green and Photo uses warning orange. | Use neutral surfaces and sage icon treatment for all capture modes. |
| Source card | `sourceCardSurface`, `sourceCardBorder`, `sourceCardAccent` | Source treatment is improving but should be the only special proof surface. | Keep source accent; reduce competing motif elsewhere. |
| Privacy badge | `privateBadgeSurface`, `privateBadgeText` | Badge is useful but too prominent in the heavy hero. | Keep compact inline badge under subtitle. |
| Camera icon | `accent` | Green implies status/success instead of modality. | Use sage/brand icon. |
| Photo icon | `accent` | Orange implies warning/status. | Use sage/brand icon. |
| Voice icon | `accent` | Already aligned. | Keep sage. |
| Bottom input | `surfaceElevated`, `surfaceSecondary`, `borderSubtle`, `accent` | Too many controls and hard boundary above tab bar. | Hide capture shortcuts on empty landing; use a lighter top divider. |
| Tab bar | System tab bar with `accent` tint | Native and acceptable. | Keep unchanged. |
| App Lock | `appLockBackground`, `appLockSurface`, `accent` | Brand-aligned after prior pass. | Keep; do not make it look like account sign-in or encryption. |
| Destructive actions | `destructive`, `destructiveSoft`, `borderDestructive` | Correctly separated. | Keep destructive colour reserved for destructive flows only. |
| Thread motif | `brandSage` at low opacity | Large hero motif feels decorative. | Reduce size/opacity and use only as a subtle accent. |
| Metadata text | `textSecondary`, `textTertiary` | Small text can become low contrast if overused. | Keep captions short and avoid placing tertiary text on tinted surfaces. |

## Rules

- Do not use green/orange for capture modalities unless communicating real status.
- Use accent sparingly: primary action, icons, source trust and privacy reassurance.
- Source cards are allowed to feel special; ordinary memory/capture cards should stay quieter.
- Dark mode must rely on semantic surfaces, not ad hoc opacity.
