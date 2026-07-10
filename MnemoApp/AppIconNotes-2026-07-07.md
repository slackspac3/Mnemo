# App Icon Notes

Updated: 2026-07-10

The production `AppIcon.appiconset` now uses the user-approved Notebook N-A identity.

## Direction

Use the closed Notebook N-A mark:

- Soft Sage tile with the single-color Olive notebook mark.
- Dark and tinted catalog variants preserve the same geometry.
- No text.
- No transparency.
- No lock, brain, robot, chat bubble, sparkle, or cloud symbol.
- Keep enough margin for iOS rounded-square masking.

Source reference:

- `MnemoApp/Design/MnemoLogoMark.svg`

## Export Checklist

Before replacing the production AppIcon:

1. Default, Dark, and Tinted 1024 x 1024 catalog PNGs are opaque RGB.
2. Editable Default, Dark, Tinted, and Monochrome SVG masters live in `Design/AppIcon`.
3. Validate the complete icon at 180, 120, 60, 44, and 29 points.
4. Confirm the notebook, elastic, and ribbon remain legible on light and dark wallpapers.
5. Confirm the icon does not resemble a generic notes, journal, or security app.
6. Import the editable masters into Icon Composer for final Clear/system-rendered validation when GUI automation or human review is available.

## Current limitation

Icon Composer 1.6 is installed and `ictool` was inspected. `ictool` exports existing `.icon` documents but does not create them. This environment does not grant assistive access to automate the GUI, so a canonical `.icon` and Clear-mode renders remain a human-tooling review item. The app uses the validated opaque catalog variants in the meantime; no fabricated `.icon` file is committed.
