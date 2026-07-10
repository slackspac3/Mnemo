# Mnemo — Brand & UI Design Brief

Date: 2026-07-10
Status: **Approved direction, implemented on the redesign branch.** The production AppIcon still requires the human Icon Composer/Clear and small-size review gate at the end of this brief.
Audience: Codex, continuing the `ui-redesign-liquid-glass` branch.

---

## 0. What this brief decides

Three things were approved by the user in this round:

1. **Palette:** migrate the production design system to **Sage & Olive** (full token table in §2).
2. **Logo mark:** adopt **"The Notebook" (variant N-A)** — a soft-cornered pocket-notebook cover with an elastic band and a ribbon marker. Non-letter, glass-friendly, flat. Full geometry in §4.
3. **Wordmark:** separate from the icon. Set in **Newsreader** (warm editorial serif) as a *brand asset only*. **In-app UI text stays on SF** — do not add a custom UI font.

Everything else (navigation, layout, components, accessibility policy, motion policy) follows the existing `MnemoDesignDirection-2026-07-10.md`. This brief does **not** change navigation (two native tabs: Recall, Memories), retrieval, citations, persistence, capture processing, App Lock, or privacy behaviour.

The mockups in `mockups/` are faithful re-skins of the **current** screens. Because the app already renders from semantic tokens in `DesignSystem.swift`, most of this migration is: **(a) change token values, (b) remap the source/privacy roles to plum/blue-gray, (c) replace the logo mark.** The layouts do not change.

---

## 1. Design principles (unchanged, restated for context)

- Memory content and source evidence outrank decoration.
- **Olive** = actions, focus, primary controls, brand.
- **Plum** = source evidence *only* (citations, source cards). Never a general accent.
- **Blue-gray** = privacy signalling only (the "Private on this iPhone" badge, App Lock).
- Green / amber / red = semantic state only (success / warning / destructive). Never decorative.
- Glass belongs to navigation, toolbars, composer controls — never to memory text or list rows.
- Native SwiftUI controls keep native treatment and accessibility.

---

## 2. Colour token migration — `MnemoUI/Sources/MnemoUI/DesignSystem.swift`

Replace the RGB values inside `DS.Colours` with the values below. **Token names stay the same** so call sites keep compiling. Values are given as hex; convert to the existing `UIColor(red:green:blue:alpha:)` adaptive form.

### Brand constants
| Token | Value |
|---|---|
| `brandInk` | `#232820` |
| `brandParchment` → rename intent to canvas | `#F5F7F1` |
| (new intent) olive brand | `#5C6838` |

### Backgrounds / surfaces
| Token | Light | Dark |
|---|---|---|
| `backgroundPrimary` / `canvas` / `backgroundGrouped` | `#F5F7F1` | `#131711` |
| `backgroundSecondary` / `canvasSecondary` | `#ECEFE6` | `#191E15` |
| `backgroundElevated` | `#FFFFFF` | `#242C20` |
| `surfacePrimary` / `contentSurface` / `surface` | `#FCFDF9` | `#1D231A` |
| `surfaceSecondary` | `#E7ECDD` | `#2A3122` |
| `surfaceElevated` / `contentSurfaceElevated` / `controlFallback` | `#FFFFFF` | `#242C20` |
| `surfacePressed` | `#DDE3CF` | `#333B28` |
| `surfaceDisabled` | `#D5D0C8` @ 0.5 | `#28341F` @ 0.5 |

### Text
| Token | Light | Dark |
|---|---|---|
| `textPrimary` | `#232820` (HC `#000000`) | `#F2F5ED` (HC `#FFFFFF`) |
| `textSecondary` | `#667064` | `#BBC3B3` |
| `textTertiary` | `#8A917F` | `#8E9684` |
| `textOnAccent` | `#FFFFFF` | `#F2F5ED` |

### Accent (olive) — actions & focus
| Token | Light | Dark |
|---|---|---|
| `accent` | `#5C6838` | `#B8C98A` |
| `accentSoft` | `#E4EAD6` (solid pale sage) or olive @ 0.11 | `#303923` or accent @ 0.16 |
| `accentPressed` | `#4A5430` | `#9EB072` |
| `accentDisabled` | olive @ 0.28 | accent @ 0.30 |
| `controlAccent` (filled button bg) | `#5C6838` | `#5D693B` |
| `controlAccentPressed` | `#4A5430` | `#4C562F` |
| `focus` | `#5C6838` | `#B8C98A` |

### Borders
| Token | Light | Dark |
|---|---|---|
| `borderSubtle` / `separator` | `#232820` @ 0.10 (HC 0.28) | `#F2F5ED` @ 0.10 (HC 0.30) |
| `borderStrong` | `#232820` @ 0.22 (HC 0.48) | `#F2F5ED` @ 0.24 (HC 0.50) |
| `borderAccent` | `#5C6838` @ 0.24 | `#B8C98A` @ 0.28 |

### Source evidence (PLUM) — **role remap, not just a value change**
Currently these alias to `accent`. Point them at plum instead:
| Token | Light | Dark |
|---|---|---|
| `sourceAccent` / `sourceCardAccent` | `#7D5C72` | `#D1A2BC` |
| `sourceSurface` / `sourceCardSurface` | `#EFE3EA` | `#402E3A` |
| `sourceBorder` / `sourceCardBorder` | `#7D5C72` @ 0.32 | `#D1A2BC` @ 0.35 |

### Privacy (BLUE-GRAY) — role remap
| Token | Light | Dark |
|---|---|---|
| `privateBadgeText` | `#3F565A` (darker of the blue-gray for AA) | `#9CC5C4` |
| `privateBadgeSurface` | `#DDE8E7` | `#263B3B` |
| `appLockSurface` | `#FFFFFF` | `#242C20` |
| `appLockBackground` | `#F5F7F1` | `#131711` |

### Semantic state (keep current behaviour, retuned greens optional)
| Token | Light | Dark |
|---|---|---|
| `success` | `#3F7A4E` | `#7FC79A` |
| `warning` | `#B45309` (keep) | `#FBBF24` (keep) |
| `destructive` | `#B91C1C` | `#F87171` |

### Mnemo Sense (premium tier)
Out of scope for this pass. Leave `sense` / `senseLight` (violet) unchanged unless a later brief addresses the premium tier.

### Legacy aliases
Keep `brandSage`/`brandSageSoft` → map to `accent`/`accentSoft`. `brandThread` → `textOnAccent`. These exist only for compile compatibility.

> **Contrast check required after migration:** `textPrimary`/canvas, `textSecondary`/canvas, `textOnAccent`/`controlAccent`, `sourceAccent`/`sourceSurface`, `privateBadgeText`/`privateBadgeSurface` must pass 4.5:1 (normal) / 3:1 (large) in Light, Dark, and Increased Contrast.

---

## 3. Typography (unchanged in UI)

- All functional UI text: **SF / system**, existing `DS.Typography` scale. No custom font in the app target.
- Section anchors and nav prefer `.semibold` over `.bold`.
- **Wordmark** ("Mnemo") is a brand asset in **Newsreader Regular**, `letter-spacing: -0.01em`. Use only for: splash wordmark, onboarding hero, App Store, marketing. Ship it as a vector/drawn asset — do **not** bundle Newsreader as a UI font. If the splash shows the wordmark, render it from a vector asset, not a live font dependency.

---

## 4. The mark — "The Notebook" (N-A)

One idea: a pocket notebook, held closed by an elastic and marked by a ribbon. Private capture (the closed cover) + reliable recall (the ribbon keeps your place).

### Geometry (48 × 48 unit artboard, stroke width 2.4 units)
Three elements, all in a single colour per render mode:

```
Cover  (stroked):  rounded rect  x=13 y=8  w=22 h=32  corner-radius=4.5   stroke-width=2.4
Band   (filled) :  rounded rect  x=28 y=8  w=4  h=32  corner-radius=1.2
Ribbon (filled) :  path  M18 40  V45  L20.5 43  L23 45  V40  Z
```

Normalised (÷48) for a SwiftUI `Shape`/`Path` that scales to any frame:

```
cover:  RoundedRectangle in CGRect(x:0.271, y:0.167, w:0.458, h:0.667), cornerRadius 0.094 (× side)
band :  RoundedRectangle in CGRect(x:0.583, y:0.167, w:0.083, h:0.667), cornerRadius 0.025 (× side)
ribbon: move(0.375,0.833) → (0.375,0.938) → (0.427,0.896) → (0.479,0.938) → (0.479,0.833) → close
stroke width for cover = 0.05 × side
```

Recommended SwiftUI construction for `MnemoLogoMark.swift`: a `Canvas` or a `ZStack` of three `Path`s driven by a single `size` and `tint` parameter. Cover is `.stroke(tint, lineWidth: side*0.05)`; band and ribbon are `.fill(tint)`. Keep it one flat colour — **no gradients, shadows, bevels, or fake glass inside the mark.**

### Colour per mode
| Mode | Tile background | Mark tint |
|---|---|---|
| Light default | linear-gradient `#FCFDF9 → #E4EAD6` | `#5C6838` |
| Dark asset-catalog fallback | transparent, allowing the system-provided background to show through | `#B8C98A` |
| Monochrome | `#232820` | `#F2F5ED` |
| Tinted asset-catalog fallback | grayscale `#F7F7F7 → #D8D8D8` | grayscale `#303030` |

In-app (toolbar, empty state, App Lock) the mark uses `DS.Colours.accent` on the current canvas — no tile.

### Approved variations (keep for the review gate)
- **N-A — Band & ribbon** (recommended, lead). Full read.
- **N-B — Ribbon only.** Cover + ribbon, no band. Cleanest silhouette; use if 29 pt legibility of the band is marginal.
- **N-C — Evidence ribbon.** N-A but the ribbon is source-plum (`#7D5C72` / `#D1A2BC`). Ties the mark to evidence. *Note:* for the app icon, prefer single-colour (N-A); reserve the plum ribbon for in-content brand moments if desired.

See `mockups/03-mark-variations.png` and `mockups/04-icon-in-context.png`.

---

## 5. App icon

- Build the editable `.icon` in Icon Composer 1.6 from the N-A geometry at 1024 pt on the light-default tile.
- Provide Default, Dark, and Tinted layers; a monochrome master; validate at 1024 / 180 / 120 / 60 / 44 / 29 pt.
- Until the canonical `.icon` is created and approved, the asset-catalog fallback must use an opaque Default PNG, a transparent-background Dark PNG, and a grayscale Tinted PNG. These are Apple input-format requirements, not palette choices.
- No baked shadow, bevel, texture, or fake glass. Generous margin (mark occupies the central ~58% of the tile as shown).
- **Process gate:** the user approved N-A and it is installed on the redesign branch. Before release, review it at the required sizes and appearances, create the canonical `.icon` in Icon Composer, and validate Clear/system-rendered variants. Do not claim trademark clearance from visual comparison alone.

---

## 6. Screen specs

All four screens are faithful to the current layout — the change is palette + mark + the source/privacy role remap. Icons below are the existing SF Symbols (the mockups use SVG stand-ins only because SF Symbols don't render off-device; **keep SF Symbols in the app**).

### 6.1 Recall — empty state  (`ChatView.EmptyChatLanding`)
Ref: `mockups/01-recall-and-memories.png` (left).
- Nav: `gearshape` (leading, `accent`), title "Mnemo" inline, no trailing button when empty.
- Header row: **N-A mark @ ~40 pt** (`accent`) + title "What should Mnemo remember?" (`title2`, `textPrimary`).
- Subtitle (`subheadline`, `textSecondary`).
- Privacy badge: capsule, `privateBadgeSurface` bg, `privateBadgeText` text + `lock.shield.fill`, `separator` hairline. **Blue-gray, not olive.**
- Primary "Write memory": `controlAccent` fill, `textOnAccent`, `square.and.pencil`, subtitle, chevron.
- Secondary grid Voice / Camera / Photo: `surfaceElevated`, `borderSubtle`, `accent` icons.
- Hint row `arrow.turn.down.right` (`accent`) + "Save your first memory, then ask naturally."
- Composer: `controlFallback` field, `separator` border; send disabled = `accent` @ 0.28.

### 6.2 Recall — answer + source  (`ChatView.MessageBubble` + `CitationSection`)
Ref: `mockups/01-recall-and-memories.png` (right, dark).
- User bubble: `controlAccent` fill (`#5D693B` dark), `textOnAccent`, corner radius `large`, right-aligned.
- Assistant label: "Mnemo" + `bookmark` in **`sourceAccent` (plum)**.
- Answer: `contentSurfaceElevated`, `separator` border, `textPrimary`.
- "Memory used" label: `bookmark.fill` in **plum**.
- Source card (primary): `sourceCardSurface` (plum surface) bg, `sourceCardBorder` (plum) border, `doc.text` + source type in plum, "Primary" pill on `contentSurfaceElevated`, summary `textSecondary`, chevron. This is the one place plum leads.
- Composer active: `plus.circle.fill` menu (`controlAccent`), field, send (`controlAccent`).

### 6.3 Memories  (`BrowseView` + `MemoryCard` + `BrowseFilterBar`)
Ref: `mockups/01-recall-and-memories.png` (centre).
- Nav: `gearshape` leading (`accent`), `plus` trailing menu (`accent`), large title "Memories", native `.searchable`.
- Filter bar: summary text (`textSecondary`) + bordered "Filter" button tinted `accent`.
- `MemoryCard`: `memoryCardSurface` bg, `memoryCardBorder`, type-icon well `surfaceSecondary` + `borderSubtle` (icon `textSecondary`), type label caption `textSecondary`, status label (Active = filled dot `accent`; Review = `exclamationmark.circle` `textSecondary`), summary `body`/`textPrimary` (3 lines), source + date metadata `caption` `textSecondary`/`textTertiary`, chevron `textTertiary`.

### 6.4 Memory Detail  (`MemoryDetailView`)
Ref: `mockups/02-memory-detail.png`.
- Native grouped `List`, `backgroundGrouped` behind, `scrollContentBackground(.hidden)`. Sheet with grabber; nav "Memory" inline + "Done" (`accent`).
- **Saved summary** section: `bookmark.fill` label in `sourceCardAccent`→ **use `accent` (olive) here** (this is the memory's own content, not a cited source), then summary `body`/`textPrimary`.
- **Original capture** section: header `text.alignleft` + raw input `body`.
- **Details** section rows: Source / Captured / Type / Status / Tags — label `textSecondary` + icon `textTertiary`, value `textPrimary`.
- **Provenance and review**: `DisclosureGroup`, `checkmark.shield` (`accent` tint).
- **Memory controls**: Archive (`archivebox`, `textPrimary`), Delete Permanently (`trash`, `destructive`). Confirmation dialogs unchanged.

> Rule of thumb for plum vs olive: **plum only when the memory is being cited as evidence for something else** (Recall source cards). When the memory is the subject itself (Memory Detail, Memories list), labels are olive/neutral.

---

## 7. File-by-file change checklist

1. `MnemoUI/Sources/MnemoUI/DesignSystem.swift` — apply §2 token values; remap `source*` → plum, `privateBadge*` → blue-gray. No API changes.
2. `MnemoUI/Sources/MnemoUI/MnemoLogoMark.swift` — rebuild as the N-A notebook (§4). Keep the same public API (`size`, `style`) so call sites in splash / onboarding / App Lock / Chat landing / Browse empty compile unchanged.
3. `MnemoApp/Mnemo/DesignExplorationView.swift` — add a DEBUG gallery entry showing N-A / N-B / N-C at 24/32/60/1024 pt, Light/Dark/Mono/Tinted, plus the icon tile, for the review gate.
4. No layout edits required in `ChatView`, `BrowseView`, `MemoryDetailView`, `OnboardingStepView`, `SettingsView` — they inherit the new tokens. Verify plum now appears only on source cards and olive on actions after the remap.
5. The user approved N-A and the identity migration is installed on the redesign branch. Do not replace these production identity assets again without a new review gate. Signing, entitlements, and the deployment target remain out of scope.

---

## 8. Review gate (before any production identity change)

Items 1 through 5 were completed before the branch identity was installed. Item 6 must be repeated after QA fixes. Icon Composer/Clear validation and formal trademark review remain separate pre-release gates.

1. DEBUG build shows the Sage & Olive tokens across Recall, Memories, Memory Detail, capture, onboarding, App Lock, Settings — Light + Dark + Increased Contrast + Reduce Transparency.
2. Contrast audit (§2 note) passes.
3. N-A mark reviewed at 24 / 32 / 60 / 1024 pt, monochrome, dark, tinted, and safe-margin in the DEBUG gallery.
4. Similarity review of the notebook mark.
5. User approves. Only then: migrate the production AppIcon (Icon Composer output), the production `MnemoLogoMark`, and — separately, if approved — any launch treatment.
6. Re-run the full Swift test / local-check / Release matrix.

---

## 9. Mockups index (`mockups/`)

- `01-recall-and-memories.png` — Recall empty (light), Memories (light), Recall answer + source (dark).
- `02-memory-detail.png` — Memory Detail sheet (light).
- `03-mark-variations.png` — N-A / N-B / N-C, each light + dark.
- `04-icon-in-context.png` — N-A across Default / Dark / Monochrome / Tinted, small sizes (60/44/29), the Newsreader wordmark lockup, home-screen, and the construction grid.

Interactive source (Design Components, for reference): `Mnemo Screens.dc.html`, `Mnemo Index Tab.dc.html`.
