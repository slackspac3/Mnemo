# Mnemo App Icon Source

These editable SVG masters implement the approved N-A Notebook geometry on a 1024-point square canvas.

- `MnemoAppIcon-Default.svg`: light Sage & Olive presentation.
- `MnemoAppIcon-Dark.svg`: dark presentation.
- `MnemoAppIcon-Tinted.svg`: tinted-system review presentation.
- `MnemoAppIcon-Monochrome.svg`: single-color review master.

The mark uses the exact 48-unit source geometry inside a 594-point central artboard. The visible ink occupies about 27% of the tile width and 45% of its height, matching the approved small, quiet presentation in `mockups/04-icon-in-context.png`. The system applies the final app-icon mask; the sources contain no baked corner mask, shadow, bevel, texture, or glass effect.

The installed Xcode toolchain includes Icon Composer 1.6. `ictool` can export an existing `.icon` document but cannot create one. These SVGs remain the editable source of truth and should be imported in the Icon Composer GUI for final Clear/system-rendered variants when human GUI access is available.
