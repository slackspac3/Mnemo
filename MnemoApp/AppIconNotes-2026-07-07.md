# App Icon Notes

Updated: 2026-07-10

The production `AppIcon.appiconset` now uses the user-approved Notebook N-A identity.

## Direction

Use the closed Notebook N-A mark:

- Soft Sage tile with the single-color Olive notebook mark.
- Dark and tinted catalog variants preserve the same geometry.
- No text.
- Default is opaque; the Dark catalog variant uses the transparent background required by Apple's asset-catalog workflow.
- The Tinted catalog variant is grayscale so the system can apply the selected tint.
- No lock, brain, robot, chat bubble, sparkle, or cloud symbol.
- Keep enough margin for iOS rounded-square masking.

Source reference:

- `MnemoApp/Design/MnemoLogoMark.svg`

## Export Checklist

Before shipping the production AppIcon:

1. Default is an opaque 1024 x 1024 RGB PNG, Dark is a 1024 x 1024 RGB PNG with alpha, and Tinted is a 1024 x 1024 Gray Gamma 2.2 PNG.
2. Editable Default, Dark, Tinted, and Monochrome SVG masters live in `Design/AppIcon`.
3. `Design/AppIcon/export-app-icon-assets.sh` reproducibly regenerates and validates the catalog PNGs.
4. Validate the complete icon at 180, 120, 60, 44, and 29 points.
5. Confirm the notebook, elastic, and ribbon remain legible on light and dark wallpapers.
6. Review the documented category similarity at small sizes; formal trademark clearance remains outside engineering QA.
7. Import the editable masters into Icon Composer for final Clear/system-rendered validation when human GUI access is available.

## Current limitation

Icon Composer 1.6 is installed and `ictool` was inspected. `ictool` exports existing `.icon` documents but does not create them. A canonical `.icon`, Clear-mode renders, and real-device appearance review remain a human-tooling release gate. The app uses the standards-compliant asset-catalog variants in the meantime; no fabricated `.icon` file is committed and no trademark-clearance claim is made.
