# Mnemo Design Direction

Date: 2026-07-10

Status: Historical Gate B proposal. The navigation and interaction direction remains current. The palette and identity sections were superseded by the user-approved `Design/BrandBrief-2026-07-10/MnemoBrandBrief-2026-07-10.md`: Sage & Olive, Notebook N-A, and the outlined Newsreader wordmark.

## Product position

Mnemo is a private memory and recall tool, not a generic assistant. Its distinctive promise is the relationship between a natural-language answer and the saved source that supports it. The redesign should make memory content and evidence more legible while making capture faster and more consistent.

## Design principles

### 1. Memory is the content

Saved memory, recalled answer, original capture, and source evidence receive the strongest hierarchy. Surfaces, color, glass, and motion support this content rather than becoming content themselves.

### 2. Trust before spectacle

Grounding, privacy state, archive, and delete actions must be calm and unambiguous. Avoid effects that imply certainty, intelligence, or activity the app cannot verify.

### 3. Glass is functional chrome

Use system-provided glass for navigation, tab bars, toolbars, sheets, and controls when the iOS 26 SDK supplies it automatically. Use custom glass only for compact interactive control clusters where it improves hierarchy. Never turn primary memory text or every list row into glass.

### 4. Warm privacy

Mnemo should feel personal and reassuring without resembling a scrapbook or ornamental journal. Warmth comes from restrained neutrals, language, spacing, and source clarity, not yellowed backgrounds or excessive decoration.

### 5. Content-first density

Remove unnecessary card nesting and oversized empty space. Let lists scan efficiently, let long text breathe, and use whitespace to express hierarchy rather than to inflate every section.

### 6. Native interaction

Prefer standard SwiftUI tabs, navigation, search, menus, toolbars, lists, sheets, buttons, toggles, and confirmation dialogs. Custom controls must solve a demonstrated product need and retain native accessibility behavior.

### 7. Evidence stays reachable

Every cited memory remains discoverable and tappable. Source type and primary-source status use labels/icons/structure as well as color. Source cards stay visually connected to the answer and open the existing canonical detail flow.

### 8. Motion explains state

Motion confirms save, answer arrival, source reveal, filtering, and navigation continuity. It remains brief, interruptible, and nonblocking. Reduce Motion substitutes fades and removes spatial/scale-heavy effects.

### 9. Accessible by construction

Each component is designed first for Dynamic Type, VoiceOver, Reduce Transparency, Increased Contrast, Differentiate Without Color, Bold Text, and Reduce Motion. Accessibility is part of the component API, not a final audit pass.

### 10. Distinctive, not alien

Mnemo uses the closed Notebook N-A mark while keeping current Apple conventions. Brand appears through the mark, source treatment, language, and restrained accent rather than custom replacements for familiar system controls.

## Platform and Liquid Glass policy

Verified environment:

- Xcode 26.6
- iOS 26.5 SDK
- iOS 18.0 minimum deployment target

Installed SDK interfaces confirm that `glassEffect`, `Glass`, `GlassEffectContainer`, and `GlassButtonStyle` are iOS 26+. `GlassButtonStyle.init(_:)` is iOS 26.1+. Explicit use must be compile-checked and guarded with the exact availability required by the chosen API.

Policy:

- let current SDK standard tabs, bars, sheets, menus, and controls receive native system treatment
- prefer `.regular` glass for any justified custom control
- do not use `.clear` glass over Mnemo's text-first backgrounds
- do not stack glass on an opaque accent shape or glass on glass
- apply glass to the whole interactive control, not decorative children
- limit custom glass containers, especially in scrolling content
- under Reduce Transparency, replace custom glass with an opaque semantic surface
- under Increased Contrast, strengthen borders and text roles
- on iOS 18-25, preserve the same hierarchy with native material or opaque semantic surfaces
- never emulate Liquid Glass with arbitrary blur, translucent white, gradients, borders, and shadows

Proposed material roles:

- `navigationChrome`: system navigation/tab chrome; no custom material unless required
- `floatingControl`: compact iOS 26 glass control; opaque elevated fallback
- `compactControl`: native button/menu treatment; opaque fallback
- `sheetChrome`: native sheet/navigation treatment
- `contentFallback`: stable opaque content surface

The exact DS API names should be finalized during the design-system implementation after call-site mapping. They are semantic roles, not mandatory screen-specific constants.

## Navigation alternatives

### Alternative A: two native tabs with consistent capture

Recommended.

- Retain the native two-tab structure.
- User-facing labels can be reviewed as `Recall` and `Memories`; internal enum names do not need an immediate rename.
- Keep Recall/Chat as home because evidence-backed asking is Mnemo's differentiating outcome.
- Empty Recall: one primary Write action with voice/camera/photo as secondary choices.
- Active Recall: one add menu in the composer; remove the standalone microphone competitor.
- Memories/Browse: one native Add toolbar/menu control; remove the floating expandable FAB.
- Make Settings reachable through a consistent toolbar/menu path rather than only from Chat.
- Rename conversation reset from `Home` to `New conversation` with an appropriate system symbol.

Benefits:

- least behavior change and regression risk
- capture remains an action rather than a false destination
- native iOS 18 fallback and iOS 26 presentation share the same structure
- source-card-to-detail flow remains unchanged

Tradeoff:

- toolbar capture in Memories is less thumb-reachable than a floating bottom control; this should be validated on a physical device.

### Alternative B: three native tabs

Requires explicit approval.

- `Recall | Capture | Memories`
- Capture must be a stable destination with a mode chooser or recent-mode preference, not a tab that immediately presents a sheet.

Benefits:

- maximum capture discoverability and bottom reach
- one consistent entry from anywhere

Costs:

- treats a transactional action as a persistent destination
- larger navigation and return-flow change
- adds implementation and regression surface
- risks over-emphasizing capture relative to Mnemo's evidence-backed recall promise

Decision recommendation: approve Alternative A. Do not build a custom tab bar.

## Palette directions

All values below are candidates for semantic asset/token implementation, not a request to hardcode every screen. System semantic colors should remain the default for standard labels, separators, fills, and destructive states where appropriate.

### A. Refined Current Identity

Recommended. This is a controlled evolution, not a major rebrand.

Light:

- canvas `#F4F2EE`
- content surface `#FCFBF9`
- primary text `#17181C`
- secondary text `#5D616A`
- memory accent `#4438A8`

Dark:

- canvas `#111316`
- content surface `#1C1E23`
- primary text `#F4F2ED`
- secondary text `#B4B1AC`
- memory accent `#9A96FF`

Approximate candidate contrast:

- primary/canvas: 15.9:1 light, 16.6:1 dark
- secondary/canvas: 5.55:1 light, 8.71:1 dark
- white/light accent: 8.84:1
- dark accent/dark canvas: 7.25:1

Why it fits:

- preserves current ink/indigo recognition
- reduces the yellow parchment cast
- avoids an overly electric dark accent
- works with restrained warm-neutral content surfaces
- is the lowest-risk direction for icon and App Store continuity

### B. Memory Dusk

Light:

- canvas `#F2EFEA`
- surface `#FBFAF7`
- primary `#171A22`
- secondary `#5E606A`
- memory accent `#4D4A88`
- source accent `#3D6670`

Dark:

- canvas `#11131A`
- surface `#1C1F28`
- primary `#F2EEE6`
- secondary `#B8B3AB`
- memory accent `#A9A2E8`
- source accent `#80B4BD`

Character: calm, nocturnal, and source-distinctive. It creates a stronger separate color for evidence, but it is a meaningful identity change and requires approval.

### C. Quiet Clarity

Light:

- canvas `#F3F4F2`
- surface `#FCFCFA`
- primary `#191B1D`
- secondary `#5D6261`
- memory accent `#176C69`

Dark:

- canvas `#101413`
- surface `#1B201E`
- primary `#F1F3F0`
- secondary `#AFB6B2`
- memory accent `#64C7BF`

Character: quiet, clear, and distinctive. It has strong contrast and a privacy-oriented evergreen accent, but it abandons Mnemo's established indigo recognition.

Decision recommendation: approve A, Refined Current Identity. Reserve red, amber, and green for destructive, warning, and success semantics. Do not assign semantic status through color alone.

## Proposed semantic color roles

- canvas
- secondary canvas/grouped background
- content surface
- elevated content surface
- opaque control fallback
- glass tint and glass border
- control accent and pressed accent
- source accent, surface, and border
- primary, secondary, and tertiary text
- separator and focus
- success, warning, and destructive

Increased Contrast must select stronger token variants. Tertiary text must not carry critical memory/source information.

## Typography direction

- Keep the SF system family and semantic SwiftUI text styles.
- Use semibold more often than bold for compact navigation and section hierarchy.
- Reserve `largeTitle`/`title2` for real screen or empty-state hierarchy.
- Use `headline` for section anchors and primary row labels.
- Use `body` for saved summaries, answers, original captures, and source excerpts.
- Use `footnote`/`caption` only for genuinely secondary metadata.
- Do not render original capture text as tertiary footnote content.
- Let metadata rows stack vertically at accessibility sizes.
- Do not add a custom font.

## Brand mark concepts

### 1. Refined Mnemonic Thread

Recommended for exploration.

Optically simplify the existing continuous path into three or four decisive turns that suggest an M and a returning path at 20-24 points. Keep it recognizable without gradients and fully functional in monochrome.

Why: the existing concept already communicates continuity and avoids generic AI symbols. Refinement preserves equity and reduces similarity/replacement risk.

### 2. Recall Loops

Two asymmetric interlocking returning loops with a narrow shared junction. Negative space can suggest M/continuity without becoming a literal infinity symbol.

Risk: crowded category and higher similarity risk. Requires external/human similarity review.

### 3. Memory Aperture

Two or three offset fragments converge around a protected central opening, suggesting fragments becoming coherent without using a padlock.

Risk: may read as a camera aperture or generic layers at small sizes.

Decision recommendation:

- retain the current production mark during initial implementation
- create a DEBUG-only exploration for Concept 1 at toolbar, onboarding, App Lock, monochrome, dark, tinted, and icon-preview sizes
- do not replace production AppIcon assets until 24, 32, 60, and 1024-point/pixel review, safe-margin review, Icon Composer variants, and similarity review pass

The current AppIcon catalog has no production artwork filenames, so icon work is a separate deliverable rather than a blind replacement.

## Flagship Chat direction

### Empty state

- lead with the literal product task: save what matters, then ask naturally
- retain one short private/on-device signal
- show Write memory as primary
- show secondary capture modes without equal visual weight
- show example recall questions only after at least one relevant saved memory exists
- avoid assistant/persona framing

### Messages

- user message may use a compact accent bubble
- assistant answer should use a stable, less bubble-like content treatment with comfortable line length
- remove automatic timestamp noise or reveal it contextually
- keep links and selection accessible
- avoid heavy shadows

### Composer

- use native multiline text entry
- use one add menu for capture modes
- retain send as the clear primary action
- show disabled state without relying only on opacity/color
- adapt to accessibility sizes by stacking or simplifying controls
- under Reduce Transparency, use an opaque elevated surface

### Generation

- use `Looking through your memories` or `Recalling from saved memories`
- do not imply thought, certainty, or network activity
- use a calm progress state with no looping decorative sparkle
- transition answer and evidence separately only when that clarifies availability

### Source evidence

- visually attach evidence to the answer
- label source type and primary source structurally, not by color alone
- make every source reachable
- use a compact summary with a native disclosure/list strategy for multiple sources
- preserve canonical Memory Detail behavior and current archive/delete safety

## Browse and Detail direction

### Browse

- retain a list rather than a grid
- keep native search
- separate memory type from lifecycle/status filters
- prefer a menu or a small number of native scopes over eight mixed chips
- reduce minimum row height while allowing text to grow
- remove per-row entrance staggering
- use icon plus label for memory type/status

### Memory Detail

Order:

1. saved summary
2. original capture
3. source and date
4. type/status/tags
5. disclosed provenance and review details
6. archive/delete actions

Primary memory text uses opaque content surfaces. Internal processing details remain available without dominating the first viewport.

## Capture direction

Create one shared capture scaffold with:

- native sheet/navigation chrome
- mode title
- scroll-adaptive content
- consistent cancel/dismiss behavior
- contextual permission state
- clear primary action
- processing and recoverable error state
- save success announcement
- keyboard-safe bottom action placement

Text: maximize writing space and preserve multiline input.

Voice: show elapsed time, distinguish stop from save, reduce alarm-like pulse, and use a static state under Reduce Motion.

Image: clarify Camera vs Photo Library, show preview, offer retake/choose another, describe OCR as extracted text that can be reviewed, and support image accessibility descriptions.

## Onboarding, App Lock, and Settings direction

### Onboarding

Three stages:

1. Remember privately
2. Ask naturally
3. Verify the source

Use short copy, Back after the first page, scroll-adaptive content, and contextual permissions. No forced or cinematic animation.

### App Lock

Use the mark, concise biometric/passcode language, one clear retry action, and VoiceOver announcement/focus for lock and error states. Avoid a large decorative security card.

### Settings

Use restrained native list hierarchy:

- Privacy and Security
- Memory and Backup
- Data Management
- Internal Diagnostics in DEBUG

Remove inactive coming-soon rows from the normal product experience. Keep destructive controls separated and confirmed.

## Launch and motion direction

Default recommendation: do not add a blocking post-launch logo reveal.

First fix continuity and duration:

- keep the static system launch screen minimal
- make the first real frame visually continuous
- do not tie a brand reveal to long initialization or DEBUG backfill
- show App Lock or Recall as soon as state is ready

If a later reviewed reveal is approved:

- overlay already available real content
- maximum 450-650 ms target, never over 800 ms
- run only on genuine cold start
- never block interaction
- use opacity only under Reduce Motion
- do not use sound, a spinner, or simulated loading

Motion roles:

- quick press feedback
- content/state crossfade
- source reveal
- saved confirmation
- archive removal
- calm unlock transition

Haptics remain short and causal for save, success, warning, archive, and destructive confirmation. They complement visible feedback and should not automatically disappear with Reduce Motion.

## Accessibility acceptance criteria

- no critical label or memory content clipped at accessibility Dynamic Type sizes
- non-scrolling fixed layouts replaced where content can grow
- 44 by 44 point minimum target for every action
- meaningful VoiceOver labels, values, hints, grouping, actions, and state announcements
- logical focus order and focus recovery after sheets/errors
- minimum 4.5:1 normal text contrast and 3:1 large/bold text, checked in light/dark and Increased Contrast
- opaque semantic fallbacks under Reduce Transparency
- status never communicated through color alone
- spatial/scale-heavy motion replaced by fades under Reduce Motion
- hardware/software keyboard never obscures primary capture/send actions
- no text embedded in images and layouts remain localization-ready

## Implementation sequence after approval

1. Design-system semantic roles, accessibility policies, shared buttons/surfaces, and preview gallery.
2. Chat, composer, generation, and source evidence prototype.
3. Screenshot/accessibility review gate on iOS 18 fallback and iOS 26.5 native path.
4. Browse and Memory Detail.
5. Shared text/voice/image capture scaffold.
6. Onboarding, App Lock, Settings, and Backup.
7. Approved mark exploration and optional launch transition.
8. Full build, regression, accessibility, and performance validation.

Business logic, retrieval, Foundation Models integration, citations, fidelity validation, persistence, source mapping, archive/delete semantics, Core Spotlight privacy, App Lock semantics, and capture processing remain outside redesign scope.

## Final approved supersession

The user subsequently approved:

1. Navigation Alternative A: retain two native tabs and consolidate capture.
2. Sage & Olive semantic palette from `Design/BrandBrief-2026-07-10/MnemoBrandBrief-2026-07-10.md`.
3. Notebook N-A production mark and AppIcon direction.
4. Outlined Newsreader wordmark for brand lockups only; SF remains the functional UI font.
5. A static, nonanimated in-app initialization frame with no sound, spinner, or cinematic delay.

The earlier palette and mnemonic-thread sections above remain as historical exploration, not the implemented direction.
