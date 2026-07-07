# App Icon Notes - 2026-07-07

This pass did not replace the production `AppIcon.appiconset`.

## Direction

Use the Mnemonic Thread mark:

- Deep ink rounded-square tile.
- White continuous thread mark.
- No text.
- No transparency.
- No lock, brain, robot, chat bubble, sparkle, or cloud symbol.
- Keep enough margin for iOS rounded-square masking.

Source reference:

- `MnemoApp/Design/MnemoLogoMark.svg`

## Export Checklist

Before replacing the production AppIcon:

1. Export a 1024 x 1024 PNG with no alpha channel.
2. Preview at homescreen size and App Store size.
3. Check on light and dark wallpapers.
4. Check the iOS rounded-square mask.
5. Confirm the thread remains recognisable at small sizes.
6. Confirm the icon does not look like a generic security/vault app.
7. Commit only the final asset set, not intermediate experiments.

## Reason Deferred

Generating a full icon set inside this pass would risk committing low-quality raster experiments. The safer launch path is to use the new in-app `MnemoLogoMark` immediately and export the production AppIcon from the documented vector source after visual QA.
