# Motion Design Notes - 2026-07-07

Build reviewed: `8efc0e6096f043b4d71bda0203dbcab8158d670f`

Motion principle: **state explanation, not decoration.** Mnemo should feel native and calm. Use short fades, slight rises and subtle press feedback. No loops, sparkle, confetti or dramatic movement.

| Motion | Where used | Purpose | Duration/style | Reduce Motion behaviour |
| --- | --- | --- | --- | --- |
| First screen appearance | Chat landing | Let the capture invitation settle without making the page feel animated. | `cardAppearTransition` only on the top intro group. | Opacity only. |
| Capture card press | Landing capture actions | Give tactile feedback to custom buttons. | `MnemoPressableButtonStyle`, 0.15s quick. | Opacity only, no scale. |
| Capture review appearing | Text capture review | Show the memory object was formed for review. | Gentle card appear. | Opacity only. |
| Saved memory transition | Browse cards | Make empty-to-content feel responsive. | Gentle card appear. | Opacity only. |
| Source card reveal | Chat citations | Signal "this is why Mnemo answered." | Short source reveal, 0.22s. | Opacity only. |
| App Lock appear | App Lock overlay | Cover private content calmly. | Short fade/scale. | Opacity only. |
| Toolbar state | Home button appears only after conversation exists. | Avoid a useless control on the landing screen. | Standard fade. | Opacity only or no animation. |

## Intentionally Avoided

- Looping thread animations.
- Confetti after save.
- Sparkle or magic effects.
- Large hero movement.
- Motion that delays capture or recall.
