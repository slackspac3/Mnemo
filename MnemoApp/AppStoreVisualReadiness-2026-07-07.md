# App Store Visual Readiness - 2026-07-07

Build under review: `0abee78b4a67dc518385b341fd1eeb1e2e2605ba` plus the V1 Signature UI polish changes in this branch.

This document is a product/design readiness note, not final screenshot approval. No private screenshots are committed.

| Screenshot candidate | What it should communicate | Current readiness | Remaining polish |
| --- | --- | --- | --- |
| Onboarding | Mnemo is a private memory layer, not an account-based chatbot. | Stronger with the Mnemo mark and thread motif; copy remains no-account and local-first. | Production screenshot capture on physical device still pending. |
| Chat recall with source | Ask naturally and see the saved memory used as evidence. | Strong. Source cards now have a primary evidence treatment and clearer tap affordance. | Validate final line wrapping on physical device sizes and large Dynamic Type. |
| Text capture | Save a memory quickly and review it before persistence. | Stronger. Review card now feels like a memory object instead of a plain form result. | Voice/image capture screenshots remain physical-device validation items. |
| Browse | Saved memories feel organised and local. | Improved. Memory cards now share the thread-object language and metadata rhythm. | Future grouping could improve dense libraries, but not needed for V1. |
| App Lock | Mnemo can be protected by the device unlock flow without an account. | Improved. App Lock now uses the Mnemo mark and calm lock surface. | Real Face ID, Touch ID and passcode fallback remain physical-device-only. |
| Settings privacy | No account, local-first, inactive future features are honest. | Acceptable. This pass intentionally avoided overdecorating Settings. | Continue checking copy before App Review submission. |

## App Icon

The production AppIcon asset was not replaced in this pass. The in-app Mnemo mark and thread motif were improved and reused, but final icon export remains a separate design/export task to avoid low-quality raster churn or large generated asset sets.

## Visual Positioning

- Mnemo should look calm, premium and private.
- Source cards should be the most screenshot-worthy proof surface.
- App Lock should feel reassuring without implying encryption or account sign-in.
- Empty states should teach the first action and avoid generic AI branding.

## Recommended Screenshot Fixtures

Use benign, non-sensitive sample memories for public assets:

- "Parking is Level 4, Row C."
- "The blue notebook is in the top desk drawer."
- "For the product review, send the notes by Friday."

Avoid credentials, health details, family/private attributes, API keys, financial data, or anything that makes Mnemo look like a secrets vault. App Lock should not be a primary public screenshot until real Face ID, Touch ID and passcode fallback have been validated on device.

## Explicitly Not Claimed

- No physical-device biometric validation was performed by this document.
- No iCloud recovery reliability claim is made here.
- No cloud AI, Foundation Models or MLX production capability is implied.
- No account, login or remote identity is part of V1.
