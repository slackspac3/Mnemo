# Mnemo Apple Design Deep Dive

Date: 2026-07-10

Branch: `ui-redesign-liquid-glass`

Repository state reviewed: `bd0628c9e92f57639247a17a5f89c72cd1740edd`

Status: research and diagnosis complete; no second-pass UI implementation is authorized by this document.

## Executive conclusion

The current redesign improved accessibility, source reachability, capture consistency, and light/dark support, but it did not yet reach the required identity or craft bar.

The main problem is not insufficient glass or insufficient decoration. It is an incomplete and fragmented product identity combined with too many equally weighted surfaces and controls.

Mnemo should be developed as a **quiet memory instrument**:

- content-first like iA Writer and Primary
- operationally obvious like Flighty
- progressively disclosed like Tide Guide and Guitar Wiz
- visually recognizable through one ownable memory-thread identity
- native in navigation and controls, but not visually anonymous
- calm and precise rather than styled like a generic AI chat product

The next pass must begin with identity and launch continuity, then simplify hierarchy. It should not begin by recoloring more cards.

## Research scope

Three parallel research tracks were completed:

1. Current Apple design principles, HIG, Liquid Glass, SwiftUI, branding, app icons, launch, motion, color, typography, and accessibility.
2. Apple Design Awards and linked Apple developer stories from 2022 through 2026.
3. Direct audit of Mnemo source, assets, screenshots, design-system components, and existing review documents.

Only official Apple design and platform sources were used for platform guidance.

## WWDC26 update

The study includes Apple's current WWDC26 design guidance, not only the WWDC25 sessions that introduced Liquid Glass.

The [WWDC26 Design guide](https://developer.apple.com/wwdc26/guides/design/) identifies four directly relevant areas for Mnemo:

- current design principles
- brand expression within the iOS content layer
- intentional search placement and filtering
- continued Icon Composer refinement

### Brand belongs primarily in content

Apple's WWDC26 branding guidance separates an app into a familiar UI layer for global navigation and actions and a content layer where distinctive brand expression belongs. Native tab bars, toolbars, menus, and sheets should provide familiarity. Mnemo's identity should appear through memory content, the returning-path mark, source treatment, palette, writing, and a small number of signature moments rather than through heavily customized bars. [Communicate your brand identity on iOS](https://developer.apple.com/videos/play/wwdc2026/251/)

This strengthens the recommendation to:

- keep navigation chrome native and restrained
- remove accent tint from secondary toolbar commands
- stop repeating the logo in utilitarian views
- express Mnemo through the empty home state, evidence relationship, and memory-saved feedback

### Search placement must communicate scope

WWDC26 search guidance says placement changes people's understanding of what is being searched. Memories currently has a tab-specific search, so an inline field associated with the `Memories` title remains more appropriate than adding a global Search tab. [Design intuitive search experiences](https://developer.apple.com/videos/play/wwdc2026/292/)

It also changes the filter recommendation:

- start with broad memory search
- reveal only contextual filters that help narrow active results
- avoid presenting two filter controls before any memories exist
- provide a clear no-results state that includes the search term
- consider recent searches only if they provide enough value to justify retaining that private local history

### Names must belong, set expectations, and work everywhere

Apple's WWDC26 naming criteria are that a name belongs in the app, sets the right expectation, and works everywhere. [Craft clear names for features and labels in your app](https://developer.apple.com/videos/play/wwdc2026/290/)

Mnemo implications:

- `Memories` is clear and consistent with the product model
- `Recall` is distinctive but must be tested against the more literal `Ask` for first-use comprehension
- capture actions should consistently use verbs such as `Write`, `Record`, `Take Photo`, and `Choose Photo`
- internal or speculative labels such as `Mnemo Sense` need a clear user outcome before appearing in production Settings
- source labels must set an evidence expectation without exposing implementation terminology

### WWDC26 SwiftUI APIs target the next toolchain

`What's new in SwiftUI` at WWDC26 describes refreshed Liquid Glass behavior and new toolbar visibility, overflow, pinned-placement, minimize-on-scroll, prominent-tab, and resizability APIs for the 2027 OS releases and Xcode 27. [What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/)

Mnemo is currently verified with Xcode 26.6 and an iOS 26.5 SDK. Therefore:

- WWDC26 design principles and interaction guidance apply now
- Xcode 27 and iOS 27 APIs must not be copied into the implementation yet
- toolbar priority and overflow behavior should first be achieved with APIs available in the installed SDK
- new APIs can be evaluated only after a deliberate toolchain upgrade and exact availability inspection
- the iOS 18 minimum deployment target must remain unchanged

This distinction prevents a current design study from becoming an accidental beta SDK migration.

Do not use the following Xcode 27 or iOS 27 features in the current implementation:

- prominent tab roles
- toolbar-item `visibilityPriority`, `ToolbarOverflowMenu`, or `topBarPinnedTrailing`
- navigation-bar `toolbarMinimizeBehavior`
- `swipeActionsContainer`
- Xcode 27 resizable Live Previews
- SF Symbols 8-only names, Draw effects, or Variable Draw behavior

`tabBarMinimizeBehavior` is an iOS 26-era API discussed at WWDC25. It must not be confused with the new WWDC26 navigation-bar `toolbarMinimizeBehavior` API.

### Accessibility and long-form memory content

Apple's WWDC26 accessibility sessions reinforce that Mnemo's saved memories and answers are reading content, not merely labels inside cards. Native `Text`, selectable text, and `TextEditor` behavior should be preserved so VoiceOver, Speak Screen, text selection, and granular navigation remain available. Custom-rendered text would create unnecessary accessibility work. [Enhance the accessibility of your reading app](https://developer.apple.com/videos/play/wwdc2026/219/)

Any custom capture, source, waveform, or branded control must translate visual cues into explicit labels, values, traits, and actions. Switch Control, Voice Control, and VoiceOver must reach the same operations as direct touch. Familiar actions should continue to use native buttons and controls wherever possible. [Refine accessibility for custom controls](https://developer.apple.com/videos/play/wwdc2026/220/)

### Scrolling and responsiveness

WWDC26's lazy-stack guidance applies directly to Chat and large memory collections. Mnemo should keep persistent row state in models or bindings, avoid filtering by conditionally omitting leaf views inside `ForEach`, avoid layout-changing work in `onAppear`, and avoid changing row geometry after it appears. Prefetch-friendly setup and stable subview counts reduce hitches and scroll-position jumps. [Dive into lazy stacks and scrolling with SwiftUI](https://developer.apple.com/videos/play/wwdc2026/321/)

Responsiveness must be measured rather than inferred from screenshots. The implementation review should use Time Profiler, Swift Concurrency, and System Trace when launch, capture processing, Chat generation, or list scrolling shows a hitch. [Profile, fix, and verify: Improve app responsiveness with Instruments](https://developer.apple.com/videos/play/wwdc2026/268/)

### AI responsibility safeguards

Apple's Responsibility principle requires anticipating inaccurate intelligent output and adding safeguards where it can change a person's data. For Mnemo:

- never silently rewrite the meaning of a saved memory
- present spelling and capitalization changes as a preview requiring confirmation
- preserve the original capture
- keep grounded source evidence and deterministic fallback as trust safeguards
- do not present technical model confidence as factual certainty
- keep meaning-changing and destructive actions reversible or explicitly confirmed

These requirements support the existing correction-review behavior and prevent visual polish from obscuring uncertainty.

### Icon Composer is available now

The installed environment contains Xcode 26.6 build 17F113 and Icon Composer 1.6 at `/Applications/Xcode.app/Contents/Applications/Icon Composer.app`. Production icon work does not need to wait for Xcode 27.

The editable `.icon` source should define Default, Dark, and Mono authoring modes, then be reviewed in default, dark, clear light/dark, and tinted light/dark contexts. Flattened exports are for marketing and communication assets, not the canonical production source. [Icon Composer](https://developer.apple.com/icon-composer/)

## Apple principles applied to Mnemo

Apple's current principles are Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, and Delight. Apple explicitly distinguishes simplicity from visual minimalism and delight from decorative effects. [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles) [Principles of great design](https://developer.apple.com/videos/play/wwdc2026/250/)

### Purpose

Mnemo exists to help a person capture something, recall it later, and verify the source.

Consequences:

- memory text, recall answers, and source evidence must dominate the hierarchy
- capture and ask must be immediately understandable as different actions
- every persistent control or label must serve capture, recall, evidence, or safety
- decorative privacy and AI language must not crowd out the actual memory

### Agency

People must remain in control of what is saved and changed.

Consequences:

- keep editable capture review and correction approval
- retain archive/delete confirmation and clear escape routes
- never trap people behind launch, onboarding, generation, or save animation
- make it easy to return, cancel, retry, or keep original wording

### Responsibility

Privacy and grounded answers are product behavior, not a decorative theme.

Consequences:

- keep source evidence visible and factual
- avoid AI spectacle, fake thinking language, and certainty theater
- explain permissions at the moment they are needed
- show privacy status where it changes a decision, not as a badge on every screen

### Familiarity

Common actions should look and behave like iOS.

Consequences:

- retain native tabs, navigation stacks, search, menus, sheets, lists, and dialogs
- use SF Symbols for familiar commands
- do not replace familiar controls with bespoke branded equivalents
- keep frequent actions in stable locations

### Flexibility

The same anatomy must work across appearance, accessibility settings, device sizes, and input modes.

Consequences:

- system text styles and adaptive layout are mandatory
- Reduce Motion, Reduce Transparency, Increased Contrast, Bold Text, Differentiate Without Color, and VoiceOver are first-class variants
- fixed rows of capture buttons must adapt or collapse at large text sizes
- older supported iOS versions must preserve hierarchy without fake Liquid Glass

### Simplicity

Apple says simplicity is not hiding everything in one place. It is removing friction while providing enough context to act confidently.

Consequences:

- flatten decorative containers and card nesting
- use spacing, alignment, weight, and order before adding a surface
- progressively disclose metadata and provenance
- remove repeated controls and instructions
- make one primary action obvious per state

### Craft

Logo, app icon, launch continuity, typography, motion, performance, and small states collectively communicate quality and trust.

Consequences:

- an empty AppIcon catalog is a release blocker
- mark geometry must be authored once and reused everywhere
- light and dark identity must be intentionally related
- icon alignment, state feedback, scrolling, and transitions need screenshot and device review

### Delight

Apple describes delight as the result of care, not confetti or extra flourishes.

Mnemo's intended emotion is **calm confidence**.

Consequences:

- one restrained memory-saved signature interaction is enough
- source reveal should feel clear and connected, not theatrical
- the product voice should be concise, warm, and factual
- generic AI sparkles, animated gradients, and ornamental glass are out of scope

## What award-level Apple design consistently does

Apple's award corpus shows recurring patterns that are directly relevant to Mnemo. [2026 Apple Design Awards](https://developer.apple.com/design/awards/) [2025 Apple Design Awards](https://developer.apple.com/design/awards/2025/) [2024 Apple Design Awards](https://developer.apple.com/design/awards/2024/)

### The task stays dominant

- Primary is praised for a minimal UI that gets out of the way of the story.
- iA Writer focuses interaction on the words.
- Flighty keeps essential information immediately available in a stressful context.

Mnemo implication: Chat should feel like a focused recall and reading surface, not a messenger full of framed modules.

### Identity comes from one product-specific idea

- Halide builds identity from camera tactility, typography, and one active-state accent.
- Bears Gratitude uses one coherent illustration language as the product's heart.
- Tide Guide ties palette and motion to the sky and water it represents.
- Vocabulary is praised for consistent illustration, balanced type and iconography, rhythm, and haptics.

Mnemo implication: the memory thread or returning path must become one coherent system across icon, mark, source affordance, and save confirmation.

### Native does not mean anonymous

- Flighty uses familiar platform surfaces while remaining unmistakably about aviation.
- Tide Guide combines framework standards with an original visual language.
- (Not Boring) Habits uses standard controls for predictability and concentrates custom expression in one signature moment.

Mnemo implication: keep native navigation and controls; concentrate custom design in content, identity, source evidence, and a restrained save moment.

### Complexity disappears through progressive disclosure

- Moonlitt hides substantial calculation behind an elegant experience.
- Guitar Wiz shows the information needed now and reveals deeper tools later.
- Tide Guide presents current conditions first and lets expert users explore layers.

Mnemo implication: sources begin compact, Memory Detail reveals provenance progressively, and Settings remains a native information hierarchy rather than decorative cards.

### Accessibility changes the actual design

- Guitar Wiz supports VoiceOver, Dynamic Type, Increased Contrast, and Differentiate Without Color as part of its core design.
- Universe iterated with blind and low-vision users.
- Speechify is praised for reducing cognitive load.
- puffies includes Reduce Motion, high-contrast, and outline options from the beginning.

Mnemo implication: accessibility variants must be visually reviewed, not only compile-checked.

### Motion and haptics are concentrated at meaningful moments

Awarded apps use feedback to reinforce completion, state, or a domain-specific interaction. They do not animate every card.

Mnemo implication: reserve distinct feedback for saved memory, source reveal, archive/delete, and unlock.

## Current Mnemo findings

### Critical: the production AppIcon is empty

`MnemoApp/Mnemo/Assets.xcassets/AppIcon.appiconset/Contents.json` declares default, dark, and tinted 1024-point slots but provides no filenames. The directory contains no production artwork.

Impact:

- Mnemo has no finished system identity on Home Screen, Spotlight, Settings, notifications, share sheets, or App Store surfaces
- the app cannot be considered visually complete or release-ready

Apple describes the app icon as a crucial identity and recognition surface. [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)

### High: the icon source is not ready for the current icon system

`MnemoApp/Design/MnemoLogoMark.svg` contains a pre-rounded tile rather than full-bleed source layers, uses a color that predates the selected palette, and is not the same implementation as the SwiftUI production mark or DEBUG exploration mark.

Apple's current icon guidance favors simple frontal artwork, fewer layers, breathing room, rounded internal geometry, and removal of baked-in shadows, bevels, and material effects so Icon Composer can apply system treatments. [Say hello to the new look of app icons](https://developer.apple.com/videos/play/wwdc2025/220/) [Create icons with Icon Composer](https://developer.apple.com/videos/play/wwdc2025/361/)

### High: AccentColor is also unfinished

`MnemoApp/Mnemo/Assets.xcassets/AccentColor.colorset/Contents.json` contains no explicit color components.

Impact:

- system controls not explicitly overridden can fall back to system blue
- the product accent is not guaranteed to stay coherent across native components

### High: launch continuity is not configured

There is no explicit appearance-aware launch background or launch asset configuration. The system can show a default light or dark frame before the SwiftUI root appears.

`SplashView.swift` then displays a centered filled logo until application initialization completes.

Apple's launch guidance is explicit:

- launch instantly
- make the launch screen nearly identical to the first real frame
- do not treat launch as an About screen or branding opportunity
- avoid a logo unless it is a fixed part of the real first screen

[Launching](https://developer.apple.com/design/human-interface-guidelines/launching) [Branding](https://developer.apple.com/design/human-interface-guidelines/branding)

### High: the in-app splash duration is service-bound

`AppRootView.swift` shows `SplashView` while `AppState.isInitialised` is false. Initialization includes store and DEBUG work, so logo display duration is not a controlled brand reveal.

Impact:

- a slow initialization turns a brief transition into a blocking splash
- a launch-time service problem becomes a visible brand inconsistency
- the user cannot reach meaningful content immediately

### High: the brand has several competing representations

Current representations include:

- `MnemoLogoMark` with a dark or purple rounded tile
- `MnemoThreadMotif` as a faint looping watermark
- a separate SVG path and palette
- a separate DEBUG refined path
- generic `bookmark` and `bookmark.fill` symbols used as Mnemo/source identity

Impact:

- there is no single canonical silhouette
- the mark can resemble a squiggle or moustache at small sizes
- the logo, source affordance, and system icon do not reinforce one another
- light and dark appearance feel like different identities

### High: filled-mark appearance changes too much

`MnemoLogoMark` uses near-black in light appearance and purple in dark appearance.

This is not inherently invalid, but it is unresolved against the fixed dark icon source and creates the inconsistency visible in splash, onboarding, App Lock, and screenshots.

### Medium: empty-state identity is visually overdrawn

Recall and Memories place a faint thread motif behind the filled mark.

In screenshots, the combined treatment reads as a tangled translucent scribble rather than a precise brand moment. Use either the mark or a supporting motif at that scale, not both.

### High: several first screens contain too many equal controls

Recall empty state includes:

- Settings
- navigation title
- brand mark and motif
- private badge
- large text capture action
- three secondary capture tiles
- instructional footer
- disabled composer and send control
- two-tab bar

Memories empty state includes search, two filters, Settings, Add, a mark and motif, explanatory copy, another Write action, and the tab bar before any content exists.

Impact:

- no single action clearly owns the state
- multiple rounded surfaces compete for attention
- the screens look assembled from components rather than designed around a task

### Medium: secondary toolbar actions are over-tinted

Settings, Add, and other secondary toolbar symbols use the Mnemo accent directly.

Apple recommends mostly monochrome toolbar/navigation symbols and selective tint for the primary action. [Color](https://developer.apple.com/design/human-interface-guidelines/color) [Get to know the new design system](https://developer.apple.com/videos/play/wwdc2025/356/)

### High: capture shares a review but not a shared scaffold

Text, voice, and image duplicate NavigationStack, background, scrolling, Cancel placement, processing state, and title behavior.

The image flow can still be titled `Take Photo` or `Choose Photo` after it reaches final memory review.

Impact:

- the modes do not yet feel like one coherent capture system
- state and navigation language can drift

### Medium: shared high-contrast input styling is bypassed

`mnemoInputSurface()` exists, but capture editors rebuild local surfaces. They therefore do not consistently receive the shared Increased Contrast border policy.

### High: large Dynamic Type still has a rigid capture row

Chat recovery forces multiple capture options into one horizontal row and scales labels to fit.

This should become an adaptive grid, vertical list, or single native menu rather than shrinking text.

### Medium: old custom-glass capture UI remains in production source

`CaptureButton.swift` contains the removed expandable multicolor glass control even though production no longer instantiates it.

Impact:

- dead implementation contradicts the selected navigation model
- it increases the risk of reintroducing inconsistent UI

### Medium: semantic state colors are reused as categories

Browse assigns green and amber to some memory types even though the selected system reserves those colors for success and warning.

Memory type already has a label and symbol. It should use neutral or memory-accent treatments unless color carries a stable, documented meaning.

### Medium: Settings is still administratively dense

Privacy is split across several sections, and nonfunctional Mnemo Sense rows remain visible.

Removing those rows is a feature-removal decision and requires explicit approval, but they weaken the product's current focus.

### Validation gap

Repeatable populated fixtures are still missing for:

- answer with one and several sources
- missing/archived source
- capture correction review
- Memory Detail with long text and image content
- App Lock states
- Settings at accessibility sizes
- large memory collections

The current screenshots therefore underrepresent the workflows that define Mnemo's trust and content hierarchy.

## Visual north star

### Position

**Mnemo is a quiet memory instrument, not an AI assistant.**

The interface should feel:

- precise enough to trust
- personal without becoming scrapbook-like
- calm without becoming empty
- native without becoming generic
- distinctive through memory continuity, not AI symbolism

### Core visual idea

Use one **returning memory path**:

- a continuous path that subtly forms an `M`
- a visible return or connection rather than an arbitrary loop
- a simple silhouette that reads at 16 to 32 points
- rounded internal geometry compatible with the current icon system
- one to three editable vector layers
- functional in monochrome before color or material is applied

This idea should appear only where it adds identity or meaning:

- app icon
- first-run onboarding
- App Lock/privacy shield
- empty Recall or Memories state, not both mark and motif
- memory-saved confirmation
- a refined source/return affordance where appropriate

It should not replace familiar action symbols or appear on every card.

## Identity work required before further polish

Develop three related production candidates, all within the returning-memory-path territory rather than three unrelated symbols:

1. **Thread M**: the path forms a clear but understated `M` and returns inward.
2. **Recall Loop**: two asymmetric loops share one return junction without resembling an infinity logo.
3. **Memory Fold**: a folded fragment resolves into a return path and protected inner space.

Each candidate must be shown as:

- mark alone at 16, 20, 24, 32, and 60 points
- wordmark lockup
- light and dark UI mark
- monochrome
- default, dark, clear, and tinted icon appearances
- Home Screen and App Store scale
- Spotlight, notification, Settings, onboarding, and App Lock contexts

Selection criteria:

- recognizable silhouette before color
- no resemblance to a brain, sparkle, robot, chat bubble, database, or lock
- no ambiguity with a moustache, wave, infinity symbol, or generic wellness mark
- works without gradients or baked-in effects
- same identity in light and dark appearance
- compatible with Icon Composer layer and safe-area behavior

Production AppIcon replacement remains a human review gate.

## Launch correction

The launch experience should be:

1. System launch frame: appearance-aware canvas matching the true first app frame; no dark logo tile.
2. Real first frame: onboarding, App Lock, or Recall content begins immediately.
3. Optional identity continuity: only if the selected mark is a fixed part of that real first frame.

Do not:

- show a service-bound logo splash
- delay interaction for a brand reveal
- replay a reveal on foreground transitions
- use a static dark mark in both appearances

If a cold-start transition survives review, it must be under 800 ms, nonblocking, and reduce to opacity under Reduce Motion.

## Liquid Glass rules

Apple defines Liquid Glass as a distinct functional layer for navigation and controls floating above content. It warns against glass in content rows, glass on glass, mixing Regular and Clear, and tinting everything. [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)

Mnemo rules:

- let native TabView, navigation, toolbar, search, menus, sheets, and standard controls receive system treatment
- use Regular glass for any justified custom compact control
- do not use Clear glass for text-first Mnemo surfaces
- tint only a primary action or selected state
- keep secondary toolbar symbols monochrome
- keep memory, answer, source excerpt, OCR, Settings, and destructive review content opaque
- use one scroll-edge effect per view only when controls float over scrolling content
- under Reduce Transparency, use a stable opaque semantic surface
- on iOS 18 through 25, preserve hierarchy with native material or opaque semantic surfaces

[Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/) [What is new in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/256/)

## Screen direction

### Recall

- make the current task the first visual anchor, not the mark
- choose one primary empty-state capture action
- place alternative capture modes in a compact native menu or one restrained secondary group
- remove the disabled composer before a first memory if it does not perform a useful action
- keep one quiet privacy statement without a decorative badge competing with the task
- use an understated brand moment only on the empty home state

### Active Chat

- reduce assistant bubble framing; answers can read as content rather than chat balloons
- keep the user message compact and visually distinct
- make the composer the main persistent control layer
- connect source evidence spatially to the answer
- use the Mnemo mark sparingly; do not label every answer with a generic bookmark identity

### Source evidence

Source evidence should become Mnemo's signature trust interaction:

- compact source row directly under the answer
- source type icon plus label/date or short identifying metadata
- clear disclosure affordance
- one stable source accent, not success/warning color
- open canonical Memory Detail
- support one and multiple sources without nested cards

### Memories

- hide or simplify filters when the store is empty
- avoid showing Add twice
- let the native title, search, and list establish structure
- use a single precise empty-state mark, not mark plus motif
- use neutral type styling and reserve semantic colors for state

### Capture

- create one shared capture scaffold with dynamic title, Cancel, progress, error, review, and save states
- keep mode-specific content inside that scaffold
- use shared input surfaces and contrast behavior
- show only the controls relevant to the current stage
- keep the confirmed correction diff compact and factual

### Memory Detail

- treat it as the canonical source document
- lead with readable summary and original capture without oversized card framing
- keep metadata compact and progressively disclosed
- separate archive/delete from the content hierarchy
- use body text for canonical memory content unless a stronger hierarchy is demonstrated in screenshots

### Onboarding

- keep three steps maximum
- use the production adaptive mark, not a separate tile treatment
- replace the large feature card with lighter grouping or a native list rhythm
- show privacy claims as factual product behavior
- avoid turning every bullet icon into a differently colored badge

### App Lock

- keep native and calm
- use the same adaptive production mark as onboarding
- avoid security theater
- make unlock the only emphasized action

### Settings

- keep a native List
- consolidate privacy and on-device concepts where the information architecture permits
- keep destructive data actions separated
- move internal tools to DEBUG only
- decide separately whether nonfunctional coming-soon rows remain visible

## Motion and haptics

Use motion only to explain:

- a memory was saved
- an answer arrived
- a source was revealed
- a record was archived or deleted
- the app unlocked
- navigation changed level

Use short system haptics for discrete events with consistent meaning. [Motion](https://developer.apple.com/design/human-interface-guidelines/motion) [Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)

Under Reduce Motion:

- replace movement and scale with fades
- remove bounce, parallax, animated blur, and z-axis depth change
- preserve state feedback through labels, opacity, symbols, and haptics

## Implementation sequence

Do not continue with another broad screen-by-screen restyle.

### Phase 1: identity review package

- create three related mark/icon candidates
- render all required appearance and size matrices
- use the confirmed installed Icon Composer 1.6 workflow and preserve the editable `.icon` source
- request human selection before replacing production AppIcon

### Phase 2: launch and identity unification

- establish one canonical vector/path source
- unify SwiftUI mark, SVG/editable source, and icon layers
- configure launch-to-first-frame canvas continuity
- remove the service-bound dark splash mark
- populate AccentColor deliberately

### Phase 3: hierarchy and native chrome

- remove unnecessary toolbar tint
- remove dead custom capture control
- flatten repeated cards and surfaces
- reduce empty-state control count
- adopt shared capture scaffold and input treatment

### Phase 4: flagship trust flow

- refine Recall, active answers, composer, and source evidence together
- refine Memories and Memory Detail as the supporting evidence system
- add deterministic DEBUG fixtures for all trust states

### Phase 5: accessibility and craft validation

- screenshot compact, Pro, and largest iPhone sizes
- validate light, dark, Increased Contrast, Reduce Transparency, Reduce Motion, Bold Text, and AX5 Dynamic Type
- run VoiceOver traversal for every major workflow
- profile first frame, Chat scroll, Memories scroll, materials, and image rows

## Human review gates

Explicit approval is required before:

1. replacing the production app icon
2. selecting the final production mark
3. changing the two-tab navigation model
4. removing the visible Mnemo Sense placeholder rows
5. adding any post-launch animation
6. replacing a standard native control with a custom branded control

For the icon and mark gate, review must include current and proposed versions, size/appearance matrices, accessibility impact, similarity risk, implementation cost, and recommendation.

## Acceptance criteria for the next pass

The redesign is not complete until:

- AppIcon has approved production artwork for supported appearances
- there is one canonical Mnemo mark implementation
- launch screen and first frame are appearance-continuous
- no service-bound branding splash blocks the interface
- light and dark marks are clearly the same identity
- empty states have one obvious primary action
- memory and evidence content are not buried in decorative surfaces
- toolbar/navigation symbols are restrained and mostly monochrome
- every major screen has repeatable long-content and accessibility fixtures
- VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency, Increased Contrast, and Differentiate Without Color are visually and interactively verified
- generic AI decoration is absent
- Local AI grounding, citations, persistence, archive/delete safety, and privacy behavior remain unchanged

## Primary official sources

### Current principles and platform system

- [WWDC26 Design guide](https://developer.apple.com/wwdc26/guides/design/)
- [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Principles of great design, WWDC26](https://developer.apple.com/videos/play/wwdc2026/250/)
- [Communicate your brand identity on iOS, WWDC26](https://developer.apple.com/videos/play/wwdc2026/251/)
- [Design intuitive search experiences, WWDC26](https://developer.apple.com/videos/play/wwdc2026/292/)
- [Craft clear names for features and labels in your app, WWDC26](https://developer.apple.com/videos/play/wwdc2026/290/)
- [What's new in SwiftUI, WWDC26](https://developer.apple.com/videos/play/wwdc2026/269/)
- [Dive into lazy stacks and scrolling with SwiftUI, WWDC26](https://developer.apple.com/videos/play/wwdc2026/321/)
- [Profile, fix, and verify: Improve app responsiveness with Instruments, WWDC26](https://developer.apple.com/videos/play/wwdc2026/268/)
- [Meet Liquid Glass, WWDC25](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Get to know the new design system, WWDC25](https://developer.apple.com/videos/play/wwdc2025/356/)
- [Build a SwiftUI app with the new design, WWDC25](https://developer.apple.com/videos/play/wwdc2025/323/)
- [What is new in SwiftUI, WWDC25](https://developer.apple.com/videos/play/wwdc2025/256/)
- [Design foundations from idea to interface, WWDC25](https://developer.apple.com/videos/play/wwdc2025/359/)

### Identity and launch

- [Branding](https://developer.apple.com/design/human-interface-guidelines/branding)
- [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Icons](https://developer.apple.com/design/human-interface-guidelines/icons)
- [Launching](https://developer.apple.com/design/human-interface-guidelines/launching)
- [Say hello to the new look of app icons](https://developer.apple.com/videos/play/wwdc2025/220/)
- [Create icons with Icon Composer](https://developer.apple.com/videos/play/wwdc2025/361/)
- [Icon Composer](https://developer.apple.com/icon-composer/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)

### Interaction and accessibility

- [Enhance the accessibility of your reading app, WWDC26](https://developer.apple.com/videos/play/wwdc2026/219/)
- [Refine accessibility for custom controls, WWDC26](https://developer.apple.com/videos/play/wwdc2026/220/)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- [Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views)

### Apple Design Awards and stories

- [2026 Apple Design Awards](https://developer.apple.com/design/awards/)
- [2025 Apple Design Awards](https://developer.apple.com/design/awards/2025/)
- [2024 Apple Design Awards](https://developer.apple.com/design/awards/2024/)
- [2023 Apple Design Awards](https://developer.apple.com/design/awards/2023/)
- [2022 Apple Design Awards](https://developer.apple.com/design/awards/2022/)
- [Moonlitt](https://developer.apple.com/news/?id=v1nphz91)
- [Tide Guide](https://developer.apple.com/news/?id=4r9b23wx)
- [Guitar Wiz](https://developer.apple.com/news/?id=5zi5a25j)
- [Primary](https://developer.apple.com/news/?id=n7uhd8gz)
- [Flighty](https://developer.apple.com/news/?id=970ncww4)
- [Universe](https://developer.apple.com/news/?id=nzd48pl9)
- [Bears Gratitude](https://developer.apple.com/news/?id=i74v3f4r)
- [Halide Mark II](https://developer.apple.com/news/?id=x6bv1a36)
- [(Not Boring) Habits](https://developer.apple.com/news/?id=9ab1g4r3)
- [Any Distance](https://developer.apple.com/news/?id=uiiopcl8)
