# Signature UI Polish Audit - 2026-07-07

Build reviewed: `0abee78b4a67dc518385b341fd1eeb1e2e2605ba` (`Polish colour system and motion`)

Scope: V1 Signature UI and App Store Polish. The app already has the Mnemonic Thread direction, Ink and Sage palette, local App Lock, simulator smoke validation, and the validated V1 memory loop. This pass keeps behaviour stable and adds only restrained visual and motion craft.

## Audit

| Screen / Surface | Why it feels ordinary | Signature opportunity | Recommended change | Risk | Decision |
| --- | --- | --- | --- | --- | --- |
| Splash | Static logo and title look correct but do not establish a memorable first impression. | Let the mark introduce the memory-thread motif. | Add a subtle thread motif behind the logo and a short fade/scale entrance. | A long splash would slow launch. | Add motif only, keep timing short and non-blocking. |
| Onboarding | Honest copy, but some pages read like settings cards rather than a premium introduction. | Make the private memory layer feel tangible. | Add a thread-backed hero mark and keep short, emotional copy. | Too much decoration could distract from onboarding. | Use the shared motif behind the existing mark, no new steps. |
| Chat landing | Clear, but still a functional action menu. | Make this feel like the heart of the product. | Add a calm hero panel, local/private badge, and balanced capture actions. | Crowding the first screen would hurt clarity. | Refine hierarchy without adding new claims. |
| Text capture | Input and review work, but the review card does not yet feel like a saved memory object. | "Capture to Memory" should feel like Mnemo placing the memory. | Add a memory-object review card with a thread accent and gentle appear transition. | Overstating extraction precision. | Keep copy grounded: "Review memory" and "Review suggested." |
| Capture review | Current summary card is readable but generic. | Make the transformed memory visually distinct from raw input. | Use memory-card surface, thread watermark, source metadata and restrained success state. | Voice/image flows should not be destabilised. | Start with text review only where this pass touches code. |
| Browse | Memory cards look like good list rows, not proprietary memory objects. | Saved memories should feel like Mnemo objects. | Add a subtle source strip/thread accent, richer metadata rhythm and card appear motion. | Too much card chrome could reduce scan speed. | Apply small visual treatment only. |
| Memory cards | Icon wells and card surfaces vary from source-card treatment. | A consistent memory-object language can carry into screenshots. | Reuse semantic memory card tokens, accent strip and press feedback. | One-off styling drift. | Prefer small reusable helpers where practical. |
| Chat messages | Bubbles are readable but source proof is the main differentiator, not the bubbles. | Keep chat quiet so source cards carry trust. | Leave bubble structure mostly intact; improve message/source reveal timing. | Changing chat too much could affect UI smoke tests. | Keep identifiers and layout stable. |
| Source cards | Useful and tappable, but they could feel more like proof. | "Source Reveal" is Mnemo's signature trust moment. | Add primary source treatment with thread motif, accent line, clearer tap affordance and gentle reveal. | Multiple sources could become noisy. | Primary source gets emphasis, secondary remains quiet. |
| Memory Detail | Strong utility, but opening a source should feel like opening the memory object used by Mnemo. | Continue the source/memory-card language. | Add summary card motif and better metadata hierarchy without moving actions. | Delete/archive clarity must remain unchanged. | Polish surfaces only, preserve flow. |
| Settings | Calm and organised, but visually admin-like. | Privacy and App Lock should feel reassuring. | Keep native rows; add small brand header/motif only where it aids orientation. | Settings should not become decorative. | Do not overwork Settings in this pass. |
| Backup/Restore | Functional and honest. | Make backup feel subordinate to local-first promise. | Keep copy and hierarchy stable; use existing card treatment only. | Overclaiming backup reliability. | No major change. |
| App Lock | Clear but still close to a generic auth gate. | "Private Lock" should feel like Mnemo sealing the memory layer. | Add thread-backed lock card, calm brand surface and Reduce Motion-aware entrance. | Must not imply encryption or account sign-in. | Polish visuals only, no security claim changes. |
| Empty states | Helpful, but mark usage is not yet a signature system. | "Empty to Alive" can make first saved memory feel satisfying. | Use shared hero motif in empty states and gentle card insertion. | Empty states must remain instructional. | Add motif sparingly and keep CTA obvious. |
| Capture menu | Useful action entry points, but icons compete with bottom input controls. | Make capture modes feel like first-class memory inputs. | Keep card actions visually balanced with one primary write action. | More actions could confuse the landing screen. | Polish only existing actions. |
| Threads placeholder | Honest coming-soon state, visually secondary. | Keep inactive features visually inactive. | Avoid adding signature polish that makes Threads look active. | Users could think Threads works now. | Do not emphasise Threads. |
| App icon/logo usage | In-app mark exists; production icon remains a separate follow-up. | Use the mark consistently in app surfaces. | Reuse `MnemoLogoMark` and a public thread motif in Splash, onboarding, empty states and App Lock. | AppIcon asset work could introduce large binary churn. | Do not replace AppIcon in this pass. |
| Light mode | Ink and Sage are coherent, but screens vary in depth. | Richer surface layering can improve premium feel. | Apply semantic surfaces consistently and reserve accent for actions/source trust. | Low contrast secondary text. | Validate contrast by token usage and simulator run. |
| Dark mode | Mostly stable, but some brand surfaces can become flat. | Make dark mode intentional without looking cyber/security themed. | Use existing app lock/source/memory surfaces; avoid new gradients. | Muddy low contrast. | Keep dark palette token-based. |

## Signature Moments Selected

1. **The Memory Thread**
   - A subtle continuous thread motif appears behind key marks and proof surfaces.
   - Surfaces: Splash, onboarding, Chat landing, Browse empty state, App Lock, source cards.
   - Rationale: It reinforces memory continuity without adding fake intelligence or generic AI imagery.

2. **Capture to Memory**
   - The text review card becomes a polished memory object with a thread accent and gentle entrance.
   - Surfaces: Text capture review.
   - Rationale: Saving should feel deliberate and trustworthy, not like submitting a form.

3. **Source Reveal**
   - Source cards become the clearest trust evidence in Chat, with a primary source treatment and calm reveal.
   - Surfaces: Chat citations and source-card tap-through.
   - Rationale: Mnemo's promise depends on seeing why it answered.

4. **Private Lock**
   - App Lock uses the Mnemo mark, brand surface and thread motif to feel protective but not alarming.
   - Surfaces: App Lock screen.
   - Rationale: Local protection should feel premium and calm, not like account sign-in.

5. **Empty to Alive**
   - Empty states use the brand mark and thread motif, while memory cards appear as saved objects once content exists.
   - Surfaces: Chat landing, Browse empty state, memory cards.
   - Rationale: The first saved memory should make the app feel personal and alive without decorative animation loops.

## Guardrails

- No new product features.
- No sign-up, Apple Sign In, backend identity or account copy.
- No Foundation Models, MLX inference, cloud LLM fallback or autonomous behaviour.
- No RecallEngine tuning.
- No AppIcon replacement unless separately production-exported and reviewed.
- No heavy animation dependencies, custom fonts, Lottie, Rive or generated screenshots.
- Existing accessibility identifiers and simulator smoke flows must remain stable.
