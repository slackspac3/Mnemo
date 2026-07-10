# Mnemo UI Redesign Review

Date: 2026-07-10

Branch: `ui-redesign-liquid-glass`

## Outcome

The redesign keeps Mnemo's native two-tab architecture and privacy-first behavior while clarifying the product around Recall, Memories, Capture, and source evidence. It replaces screen-local visual decisions with a semantic design system, removes competing capture patterns, makes every cited memory reachable, improves memory/source hierarchy, and adds explicit accessibility policies for transparency, contrast, motion, color differentiation, focus, and large text.

Local AI answer generation, retrieval, citation/fidelity validation, persistence, archive/delete behavior, App Lock policy, and Release AI behavior remain unchanged. Capture review now includes an explicitly gated orthographic-normalization proposal: DEBUG may use on-device Foundation Models, while Release remains deterministic and never starts a normalization model session. Every proposal remains editable and requires the existing explicit save action.

## Final design principles

1. Memory is the content.
2. Trust before spectacle.
3. Glass is functional chrome.
4. Warm privacy.
5. Content-first density.
6. Native interaction.
7. Evidence stays reachable.
8. Motion explains state.
9. Accessible by construction.
10. Distinctive, not alien.

## Navigation

Selected: approved Alternative A.

- Retained native `TabView` and two persistent areas.
- User-facing tabs are now `Recall` and `Memories`.
- Recall remains the home and flagship surface.
- Active Chat uses one capture menu rather than a plus menu plus separate microphone control.
- Memories uses one native toolbar Add menu; the custom floating capture button is no longer presented.
- Settings is reachable from both tabs.
- Conversation reset is now described as `New conversation`, not `Home`.
- No custom tab bar was added.

## Palette and typography

Selected: user-approved Sage & Olive.

Key roles:

- light canvas `#F5F7F1`
- light content `#FCFDF9`
- light action/focus `#5C6838`
- dark canvas `#131711`
- dark content `#1D231A`
- dark action/focus `#B8C98A`
- source evidence only: plum `#7D5C72` light / `#D1A2BC` dark
- privacy only: blue-gray `#3F565A` light / `#9CC5C4` dark

Filled controls use a separate darker `controlAccent` role so white labels remain legible in dark appearance. Foreground-only actions use adaptive `accent`; using the filled-control color there failed dark-mode contrast. Semantic green, amber, and red remain reserved for success, warning, and destructive meaning. Light `textTertiary` deliberately uses `#6C7464` rather than the brief's `#8A917F`, raising canvas contrast from about 3.0:1 to 4.5:1.

Typography remains SF system typography with Dynamic Type. The `Mnemo` wordmark is an outlined Newsreader Regular brand asset only; no custom font is loaded or bundled. Its editable SVG, generator, source hash, copyright, and OFL text live under `Design/Wordmark`.

## Liquid Glass and fallbacks

- Verified toolchain: Xcode 26.6 with iOS 26.5 SDK.
- Minimum deployment target remains iOS 18.0.
- Explicit custom glass is centralized in `MnemoFloatingControlButtonStyle`.
- Custom glass is limited to compact interactive floating controls on iOS 26+.
- Content cards, memory text, OCR, source evidence, and list rows remain opaque.
- iOS 18-25 use native material or semantic opaque fallbacks with the same hierarchy.
- Reduce Transparency forces opaque semantic surfaces.
- Increased Contrast strengthens borders through `colorSchemeContrast`.
- Direct screen-local `glassEffect` calls were removed.

## Chat and sources

- Assistant answers use stable, restrained content surfaces; user messages retain a compact accent treatment.
- Decorative timestamps were removed from every message.
- Generation uses `Looking through your memories` with a calm progress state.
- The composer uses one capture menu, multiline input, and a clear send action.
- The composer becomes opaque under Reduce Transparency.
- Source evidence is structurally connected to the answer.
- Every cited memory ID remains tappable, including citations missing display metadata.
- More than two sources use an accessible disclosure instead of becoming `not shown` text.
- Primary source, source type, summary, and position have explicit VoiceOver semantics.
- Source taps continue to open the canonical Memory Detail flow.

## Browse and Memory Detail

- Browse is now Memories and remains a single-column list.
- Mixed chips were replaced with separate native Type and Status menus.
- Filter menus expose selected state with checkmarks and VoiceOver values.
- Row entrance staggering was removed.
- Rows are denser and use icons plus labels rather than color alone.
- Metadata stacks at accessibility Dynamic Type sizes.
- Memory Detail now orders summary, original capture, source/date, type/status/tags, then disclosed provenance/review details.
- Original capture is body text and supports text selection.
- Archive and permanent delete remain separate, confirmed actions.

## Capture

- Text, voice, and image flows now use scroll-adaptive layouts.
- Primary/secondary actions use shared design-system button styles.
- Text and transcript editors remain multiline and keyboard-safe.
- Voice capture shows elapsed time and uses calmer, non-looping recording feedback.
- Reduce Motion uses a stable waveform level.
- Image capture preserves the one-tap camera route.
- OCR text is presented as reviewable `Text found in image`, not as guaranteed truth.
- Image context is multiline, and users can choose another image before saving.
- Save/process errors are announced to VoiceOver.
- Save confirmation receives accessibility focus and remains until explicit dismissal for VoiceOver, Switch Control, or accessibility Dynamic Type.
- Text, voice, and image sheets cannot be dismissed while persistence is committing; noncommitting preparation can still be cancelled.
- Credentials, URLs, email addresses, handles, identifiers, quantities, dates, intentional casing, and negation are protected before a model proposal can reach review.

## Onboarding, App Lock, and Settings

Onboarding is now three stages:

1. Remember privately.
2. Ask naturally.
3. See the source.

It supports Back navigation, a correctly initialized progress value, a labeled progress element, scrolling, and unrestricted feature text. Default-size baseline truncation is removed in the after screenshots.

App Lock removes the oversized security card, retains native biometric/passcode wording, keeps retry behavior, and focuses errors for VoiceOver without duplicate announcements.

Settings remains a native List. Privacy, on-device behavior, App Lock, Memory, Backup, Internal DEBUG diagnostics, and Data Management have clearer grouping. Settings and Privacy & Processing now use the Sage grouped canvas consistently with Backup and Memory Detail. Nested Backup navigation was removed.

## Brand, icon, and launch

Concepts considered:

1. N-A: band and ribbon.
2. N-B: ribbon only.
3. N-C: evidence-plum ribbon for in-content brand moments.

Selected and installed on the redesign branch: Notebook N-A, a flat closed pocket-notebook cover with an elastic band and ribbon marker. The DEBUG Design Preview shows N-A/N-B/N-C, production N-A at small sizes, simulated Default/Dark/Monochrome/Tinted presentations, the shared production lockup, context previews, accessibility status, and a 1024-point master.

- Production `MnemoLogoMark`: replaced with exact N-A geometry and reused by Recall, onboarding, App Lock, privacy shield, splash, and the DEBUG gallery.
- Production wordmark: outlined Newsreader Regular with one shared `MnemoBrandLockup` ratio; the wordmark uses the primary ink/text role rather than olive in the approved lockup.
- Redesign-branch `AppIcon`: an opaque RGB Default, transparent-background RGB Dark, and Gray Gamma 2.2 Tinted 1024 catalog variant generated from editable SVG masters. A monochrome SVG master is retained. These are installed pre-release artwork, not a substitute for final Icon Composer/Clear validation.
- Production `AccentColor`: adaptive Olive values for light and dark.
- Similarity review covers Apple Notes, Goodnotes, Notability, Zoho Notebook, Bear, Day One, Agenda, and Notebooks.
- Static system launch behavior remains unchanged.
- The in-app initialization frame is static, nonanimated, and uses the shared mark/wordmark lockup.
- No blocking brand reveal, sound, spinner, or cinematic launch animation was added.

Icon Composer 1.6 is installed, but its CLI only exports existing `.icon` documents and GUI automation is unavailable without macOS assistive access. Editable SVGs are therefore the current source of truth; a canonical `.icon` and real Clear renders remain a human pre-release task.

## Motion and haptics

- Shared motion timings are shorter and less spring-heavy.
- Reduce Motion changes spatial transitions to fades and stabilizes the recording waveform.
- Per-row Browse entrance animation was removed.
- Chat source disclosure and state changes remain brief and interruptible.
- Starting a new conversation invalidates and cancels pending recall presentation, preventing late orphan answers.
- Haptics no longer disappear merely because Reduce Motion is enabled; tactile feedback is independent nonvisual confirmation.

## Accessibility results

### VoiceOver

- Runtime accessibility hierarchy was captured for onboarding, Recall, Memories, Settings, and design exploration.
- Onboarding exposes its scroll region, progress, Back, Continue, and Start actions.
- Source cards group labels, summaries, positions, values, and actions.
- Capture save, recording, transcription, processing, and error states announce or receive focus.
- Busy capture, restore, and App Lock controls retain stable accessible names and expose progress values.

### Dynamic Type and Bold Text

- Non-scrolling onboarding/capture roots were replaced with scroll-adaptive structures.
- Rigid metadata rows use `ViewThatFits` or accessibility-size stacking.
- Fixed line limits were removed from critical onboarding and save-confirmation content at accessibility sizes.
- Light, dark, and accessibility-size DEBUG previews compile.
- XcodeBuildMCP does not expose a content-size setting, and the attempted UIKit launch argument did not alter simulator text size. Full runtime accessibility-size screenshot validation remains pending.

### Transparency, contrast, and color differentiation

- Reduce Transparency opaque fallbacks are implemented and were enabled in the iOS 26.5 simulator.
- Increased Contrast was enabled in the simulator; borders use the installed `colorSchemeContrast` API.
- Browse/Detail status uses icons and labels as well as color.
- Palette contrast was reviewed against light and dark canvases. Required headline pairs pass AA in both appearances.
- Capture editors now expose a visible focus border and stronger Increased Contrast boundary.
- Foreground-only composer and floating actions use adaptive accent after dark-mode contrast review.

## Screenshot review

Before, local and uncommitted:

`/private/tmp/Mnemo-UIBaseline-2026-07-10`

Current identity review, local and uncommitted:

`/private/tmp/MnemoSageOliveReview-2026-07-10`

After captures include:

- Recall, Memories, Memory Detail, text/voice/image capture, Settings, Design Preview, and Home Screen AppIcon
- light and dark representatives
- dark Increased Contrast plus Reduce Transparency representatives

The review directory includes existing local populated Memories and Memory Detail data. No deterministic fixture was fabricated for populated Chat citations, missing sources, App Lock, or large collections; those paths remain source/build verified.

## Validation

- `git diff --check`: passed throughout implementation
- `MnemoUI`: 3 tests passed
- `MnemoMemory`: 91 tests passed
- `MnemoIntelligence`: 72 tests passed in Debug and Release package configurations
- All seven Swift packages: 197 tests passed
- `Scripts/run_local_checks.sh fast`: passed
- `Scripts/run_local_checks.sh efficiency`: passed
- Debug iOS 26.5 simulator build: passed
- Debug unsigned generic iOS build: passed
- Release unsigned generic iOS build: passed
- Release emitted only existing `mlx-swift` C++17-extension warnings from dependency source
- DEBUG-only Design Exploration and AI Lab compile only in DEBUG

## Performance observations

- No custom glass is rendered per list row or memory card.
- Browse row entrance staggering was removed.
- No continuously animated gradients, blur stacks, or per-cell GeometryReader/Canvas work was added.
- Recording animation exists only during active capture and becomes stable under Reduce Motion.
- Efficiency baseline passed. Representative recall p95: about 10.1 ms at 30 records, 34.8 ms at 100, 179.4 ms at 500, and 358.3 ms at 1,000.
- Representative vector search average: about 0.23 ms at 30 records, 0.65 ms at 100, 3.08 ms at 500, and 6.04 ms at 1,000.
- No Instruments SwiftUI trace was captured in this pass. Large populated-list scrolling and first-frame timing remain physical-device review items.

## Known compromises and human review

1. A canonical Icon Composer `.icon` and real Clear/system-rendered review require human GUI access; standards-compliant catalog variants and editable SVG masters are present.
2. The notebook metaphor has moderate category-level similarity risk even though the rendering review found low direct-rendering overlap; formal trademark clearance is outside this engineering pass.
3. iOS 18 fallback is compile-checked through the deployment target but no iOS 18 simulator runtime is installed.
4. Accessibility Dynamic Type runtime screenshots still require system text-size setup; layouts and previews compile and critical content line limits are removed at accessibility sizes.
5. Real Face ID/Touch ID/passcode, microphone, camera, OCR quality, and physical-device haptics remain device-only validation.
6. Generated system launch background cannot be color-matched without a project/build-setting change, which is explicitly excluded from this branch. The in-app initialization frame is static and nonanimated.
7. Lowercase proper-name inference requires the explicitly enabled on-device Foundation Models path. On iOS 18 or when that model is unavailable, Mnemo preserves source casing and sentence capitalization conservatively rather than guessing from a brittle name dictionary; the summary remains editable before saving.

## Safety confirmation

The redesign did not change Local AI grounding, Foundation Models answer generation, source alias mapping, citation/fidelity validation, deterministic recall fallback, persistence transactions, archive/delete safety, Core Spotlight privacy policy, App Lock policy, or Release AI behavior. Capture adds only the review-stage orthographic proposal described above; Release does not invoke Foundation Models for it, credentials never enter its generator, protected factual values are count-validated, and no correction is committed without the user's save action.

No backend, authentication, cloud LLM, Private Cloud Compute, analytics, telemetry, StoreKit, advertising, third-party UI framework, third-party font, Lottie, Rive, or remote image dependency was added.
