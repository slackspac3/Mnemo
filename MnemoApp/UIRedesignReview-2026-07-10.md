# Mnemo UI Redesign Review

Date: 2026-07-10

Branch: `ui-redesign-liquid-glass`

## Outcome

The redesign keeps Mnemo's native two-tab architecture and privacy-first behavior while clarifying the product around Recall, Memories, Capture, and source evidence. It replaces screen-local visual decisions with a semantic design system, removes competing capture patterns, makes every cited memory reachable, improves memory/source hierarchy, and adds explicit accessibility policies for transparency, contrast, motion, color differentiation, focus, and large text.

No Local AI, Foundation Models, retrieval, citation validation, fidelity validation, persistence, Core Spotlight, capture-processing, archive/delete, App Lock policy, or Release AI behavior was changed.

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

Selected: approved Palette A, Refined Current Identity.

Key roles:

- light canvas `#F4F2EE`
- light content `#FCFBF9`
- light memory accent `#4438A8`
- dark canvas `#111316`
- dark content `#1C1E23`
- dark memory accent `#9A96FF`

Filled controls use a separate darker `controlAccent` role so white labels remain legible in dark appearance. Unfilled toolbar, source, and navigation symbols use the brighter memory accent. Semantic state colors remain reserved for success, warning, and destructive meaning.

Typography remains SF system typography with Dynamic Type. Compact titles use restrained weight; memory answers, original captures, and source excerpts use body styles; caption styles are reserved for secondary metadata.

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
- Save confirmation remains longer when VoiceOver is running and receives accessibility focus.

## Onboarding, App Lock, and Settings

Onboarding is now three stages:

1. Remember privately.
2. Ask naturally.
3. See the source.

It supports Back navigation, a correctly initialized progress value, a labeled progress element, scrolling, and unrestricted feature text. Default-size baseline truncation is removed in the after screenshots.

App Lock removes the oversized security card, retains native biometric/passcode wording, keeps retry behavior, and focuses errors for VoiceOver without duplicate announcements.

Settings remains a native List. Privacy, on-device behavior, App Lock, Memory, Backup, Internal DEBUG diagnostics, and Data Management have clearer grouping. Existing Mnemo Sense placeholder rows remain present because their removal was not separately approved. Nested Backup navigation was removed.

## Brand, icon, and launch

Concepts considered:

1. Refined Mnemonic Thread.
2. Recall Loops.
3. Memory Aperture.

Selected for exploration: Refined Mnemonic Thread. A DEBUG-only Design Exploration screen shows palette, shared controls, source treatment, and the refined thread at 24, 32, 60, monochrome, and tinted presentations.

- Production `MnemoLogoMark`: unchanged.
- Production `AppIcon`: unchanged; the catalog still has no approved artwork filenames.
- No generated raster icon was fabricated.
- Static system launch behavior remains unchanged.
- The in-app initialization frame is now static, minimal, and nonanimated.
- No blocking brand reveal, sound, spinner, or cinematic launch animation was added.

## Motion and haptics

- Shared motion timings are shorter and less spring-heavy.
- Reduce Motion changes spatial transitions to fades and stabilizes the recording waveform.
- Per-row Browse entrance animation was removed.
- Chat source disclosure and state changes remain brief and interruptible.
- Haptics no longer disappear merely because Reduce Motion is enabled; tactile feedback is independent nonvisual confirmation.

## Accessibility results

### VoiceOver

- Runtime accessibility hierarchy was captured for onboarding, Recall, Memories, Settings, and design exploration.
- Onboarding exposes its scroll region, progress, Back, Continue, and Start actions.
- Source cards group labels, summaries, positions, values, and actions.
- Capture save, recording, transcription, processing, and error states announce or receive focus.

### Dynamic Type and Bold Text

- Non-scrolling onboarding/capture roots were replaced with scroll-adaptive structures.
- Rigid metadata rows use `ViewThatFits` or accessibility-size stacking.
- Fixed line limits were removed from critical onboarding and save-confirmation content at accessibility sizes.
- Light, dark, and accessibility-size DEBUG previews compile.
- XcodeBuildMCP does not expose a content-size setting, and the attempted UIKit launch argument did not alter simulator text size. Full runtime accessibility-size screenshot validation remains pending.

### Transparency, contrast, and color differentiation

- Reduce Transparency opaque fallbacks are implemented and compile-checked.
- Increased Contrast border roles use the installed `colorSchemeContrast` API.
- Browse/Detail status uses icons and labels as well as color.
- Palette contrast was reviewed against light and dark canvases.
- XcodeBuildMCP does not expose Reduce Transparency or Increased Contrast simulator toggles, so those system-setting runtime passes remain pending.

## Screenshot review

Before, local and uncommitted:

`/private/tmp/Mnemo-UIBaseline-2026-07-10`

After, local and uncommitted:

`/private/tmp/Mnemo-UIAfter-2026-07-10`

After captures include:

- Recall empty, light
- Memories empty, light and dark
- Onboarding, light and dark
- DEBUG design-system exploration
- DEBUG refined brand concept

The baseline store contained no deterministic fixtures for populated Chat, citations, missing sources, App Lock, memory detail, or large collections. Those paths were source/build verified but not represented as fabricated screenshots.

## Validation

- `git diff --check`: passed throughout implementation
- `MnemoUI`: 3 tests passed
- `MnemoMemory`: 91 tests passed
- `MnemoIntelligence`: 55 tests passed
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
- Efficiency baseline passed. Representative recall p95: about 10.4 ms at 30 records, 34.9 ms at 100, 176.6 ms at 500, and 356.2 ms at 1,000.
- Representative vector search average: about 0.23 ms at 30 records, 0.66 ms at 100, 3.01 ms at 500, and 5.93 ms at 1,000.
- No Instruments SwiftUI trace was captured in this pass. Large populated-list scrolling and first-frame timing remain physical-device review items.

## Known compromises and human review

1. Production icon replacement remains unapproved and was not performed.
2. The refined mnemonic-thread concept requires human small-size/similarity review.
3. iOS 18 fallback is compile-checked through the deployment target but no iOS 18 simulator runtime is installed.
4. Accessibility-size, Reduce Transparency, and Increased Contrast runtime screenshots remain pending because the available simulator wrapper does not expose those settings.
5. Real Face ID/Touch ID/passcode, microphone, camera, OCR quality, and physical-device haptics remain device-only validation.
6. Populated Chat/source/detail and large-memory screenshots require deterministic DEBUG fixtures or human test data in a follow-up review pass.
7. No production app icon can be shipped until approved artwork is provided through the official Icon Composer workflow.

## Safety confirmation

The redesign did not change application behavior or implementation for Local AI grounding, Foundation Models answer generation, source alias mapping, citation/fidelity validation, deterministic fallback, persistence, capture processing, archive/delete safety, Core Spotlight privacy, App Lock policy, or Release AI behavior.

No backend, authentication, cloud LLM, Private Cloud Compute, analytics, telemetry, StoreKit, advertising, third-party UI framework, third-party font, Lottie, Rive, or remote image dependency was added.
