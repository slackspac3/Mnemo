# Mnemo Wordmark Source

The production wordmark is an outlined `Mnemo` setting derived from Newsreader Regular at optical size 72 with `-0.01em` tracking. The app does not bundle or load Newsreader as a UI font. Functional interface typography remains the system font.

Source font:

- Newsreader variable font, Version 1.003
- Copyright 2020 The Newsreader Project Authors
- SIL Open Font License 1.1, included as `OFL.txt`
- Google Fonts source: `https://github.com/google/fonts/tree/main/ofl/newsreader`
- Input SHA-256: `8a08d13f8a6c0d51be379a60af84f945f65369a67e509ee3c3bdcc421254d7c1`

`MnemoWordmark.svg` is the editable outlined master. `MnemoWordmark` in `MnemoUI` is the same normalized outline rendered with SwiftUI `Canvas` so no font file or remote asset is needed at runtime.

Regenerate after obtaining the matching `Newsreader[opsz,wght].ttf`:

```sh
python3 generate_wordmark.py /path/to/Newsreader.ttf MnemoWordmark.svg
```
