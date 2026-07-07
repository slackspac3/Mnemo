# Apple-Quality Critique - 2026-07-07

Build reviewed: `8efc0e6096f043b4d71bda0203dbcab8158d670f` (`Add signature UI polish`)

Target experience: **Calm private memory, not dashboard.**

The first screen should feel like an elegant invitation: one obvious primary action, quiet secondary actions, visible privacy reassurance, enough whitespace, no random colours, and no crowded bottom controls. The desired first impression is: "I know exactly what to do, and I trust this app with personal details."

## Apple-Quality Scorecard

| Dimension | Current rating 1-10 | What is working | What feels below Apple-quality | Required change |
| --- | ---: | --- | --- | --- |
| Clarity | 6 | The app explains save, ask, and source. | The Chat landing competes with toolbar controls and bottom input. | Make the first screen a single clear capture invitation. |
| Visual hierarchy | 5 | Source cards and capture actions are distinguishable. | Hero card, primary action, secondary actions, input bar and tab bar all compete. | Remove the heavy hero card and quiet secondary capture cards. |
| Interaction | 6 | Capture, recall, and source tap-through are available. | Top Home button is visible even when already home; bottom capture shortcuts duplicate landing actions. | Show controls only when they are contextually useful. |
| Delight | 5 | The thread motif is distinctive. | The motif currently feels decorative rather than integrated into flow. | Use the motif as a small accent only where it reinforces source trust or privacy. |
| Inclusivity/accessibility | 7 | Dynamic Type tokens, VoiceOver identifiers, Reduce Motion hooks exist. | Large titles and chunky cards crowd small screens; secondary capture grid can feel dense. | Smaller headings, clearer tap targets, less vertical competition. |
| Visuals and graphics | 6 | Ink and Sage identity is calmer than generic AI branding. | Green camera and orange photo icons break palette discipline. | Use brand/neutral treatments for capture modalities. |
| Platform fit | 6 | SwiftUI, SF Symbols, native sheets, tab view and navigation are used. | Toolbar looks like floating islands, not a calm native app header. | Simplify top bar and avoid unnecessary leading actions. |
| Trust/privacy | 8 | No account/local copy is honest and visible. | Privacy badge inside a heavy hero adds another visual object. | Keep the reassurance, but make it quieter and integrated. |
| App Store screenshot readiness | 6 | Source-card recall is a strong screenshot candidate. | First screen still looks busy and dashboard-like. | Refine landing and source-card composition before screenshots. |

## Chat Landing Critique

| Area | Current issue | Required decision |
| --- | --- | --- |
| Top navigation | Home and Settings appear together even on the landing screen, while compose floats separately. | Hide Home when already on the landing state; keep Settings and Write as simple native toolbar actions. |
| Hero card | Large boxed hero plus motif creates a heavy first object. | Remove the hero card chrome. Use open composition with small mark and quiet copy. |
| Headline | "What do you want to remember?" is large and can wrap awkwardly. | Use a calmer title: "What should Mnemo remember?" with title2 scale. |
| Thread motif | Large motif behind hero reads as decoration. | Reduce it to a very subtle mark accent or remove it from dense sections. |
| Privacy badge | Useful but currently another object inside a card. | Use a compact inline badge under the subtitle. |
| "Save a memory" section | Section heading plus four cards makes the screen feel like a dashboard. | Remove the heading; make Write the clear primary row. |
| Write Memory card | Too chunky for the first action. | Use a slimmer full-width primary action row with chevron. |
| Voice/Camera/Photo cards | Chunky and colour-coded with unrelated green/orange. | Make smaller neutral secondary buttons with sage icons. |
| Bottom chat input | Plus, mic, field, send, tab bar and landing actions crowd the bottom. | Hide capture shortcuts from the input while the empty landing already shows capture actions. |
| Tab bar | Native and acceptable, but competes when paired with a busy input row. | Keep native tab bar; reduce input complexity above it. |
| Colour consistency | Success/warning colours appear as category colours. | Reserve status colours for status. Use brand sage/neutral for capture modes. |
| Spacing | Too many card boundaries compress the screen. | Use whitespace as hierarchy instead of boxed surfaces. |
| One-handed use | Primary action is visible but secondary/bottom controls create many targets. | One primary action, three quiet secondary actions, then input. |

## Decision Summary

- The main landing should become an open composition, not a heavy hero card.
- The toolbar should be context-aware: no Home button on the landing state.
- Capture modalities should use one brand colour system, not category colours.
- The bottom chat input should be quieter while the empty landing is teaching capture.
- The source card remains the signature visual moment; other surfaces should not compete with it.
