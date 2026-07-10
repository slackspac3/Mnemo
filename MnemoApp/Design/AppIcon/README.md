# Mnemo App Icon Source

These editable SVG masters implement the approved N-A Notebook geometry on a 1024-point square canvas.

- `MnemoAppIcon-Default.svg`: light Sage & Olive presentation.
- `MnemoAppIcon-Dark.svg`: transparent-background Dark catalog source.
- `MnemoAppIcon-Tinted.svg`: neutral grayscale Tinted catalog source.
- `MnemoAppIcon-Monochrome.svg`: single-color review master.

The mark uses the exact 48-unit source geometry inside a 594-point central artboard. The visible ink occupies about 27% of the tile width and 45% of its height, matching the approved small, quiet presentation in `../BrandBrief-2026-07-10/mockups/04-icon-in-context.png`. The system applies the final app-icon mask; the sources contain no baked corner mask, shadow, bevel, texture, or glass effect.

[Apple's asset-catalog workflow](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) requires a transparent background for a supplied Dark icon so the system background can show through, and a grayscale image for a supplied Tinted icon. The checked-in catalog PNGs follow those requirements. Run `./export-app-icon-assets.sh` from this directory to regenerate them from the SVG masters; the script also verifies their dimensions, color spaces, and alpha state.

The installed Xcode toolchain includes Icon Composer 1.6. `ictool` can export an existing `.icon` document but cannot create one. These SVGs remain the editable source of truth and should be imported in the Icon Composer GUI for final Clear/system-rendered variants when human GUI access is available.

The approved brand brief and review mockups are committed under `../BrandBrief-2026-07-10`. Mockup backgrounds communicate visual direction only; they are not raster export specifications.
