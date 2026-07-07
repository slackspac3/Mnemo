# Colour Motion Audit - 2026-07-07

Build context: local working tree after `f61d1fc37a4ae3280fa573e41f27e7c5f12b8325`.

Pass: V1 Colour System and Motion Polish.

## Skill and Tool Discovery

| Skill / tool | Used for | Result |
| --- | --- | --- |
| XcodeBuildMCP skill | Required workflow guidance before XcodeBuildMCP simulator build/run and screenshots. | Used. Session defaults confirmed before simulator build/run. |
| `tool_search` XcodeBuildMCP tools | Simulator build/run and screenshots. | Used for app build/run and light/dark screenshot validation. |
| Dedicated design/UI/accessibility skill | Looked for a local design, animation, accessibility, or visual-review skill. | No dedicated skill was available; proceeded with native SwiftUI and existing MnemoUI tokens. |

No external colour, animation, asset, Lottie, Rive, or design SDK dependency was added.

## Audit Table

| Area | Current inconsistency | Root cause | Design decision | Implementation change | Risk |
| --- | --- | --- | --- | --- | --- |
| MnemoUI colour tokens | Brand pass introduced useful aliases, but required semantic roles were incomplete. | Screens still depended on broad `surface`, `background`, and fixed light status colours. | Lock a fuller Ink/Sage semantic system while preserving legacy aliases. | Added background, surface, text, brand, accent, border, status, source-card, memory-card, app-lock, and private-badge roles. | Low; aliases remain. |
| Dark-mode status colours | `successLight`, `warningLight`, and `destructiveLight` were fixed pale colours. | Earlier light-mode constants did not adapt to dark mode. | Use system status colours plus opacity-based soft variants. | Mapped `successSoft`, `warningSoft`, `destructiveSoft`; legacy aliases point to them. | Low; visual tone changes only. |
| Source cards | Source cards looked close to ordinary cards. | Source card surface was not distinctive enough. | Make source cards calm but recognisable trust evidence. | Added `sourceCardSurface`, `sourceCardBorder`, `sourceCardAccent`; primary source gets stronger treatment. | Low; citation identifiers preserved. |
| Memory cards | Browse/detail/thread cards used one-off `surface` styling. | No dedicated memory-card role. | Memory cards should share one library-card treatment. | Added `memoryCardSurface` and `memoryCardBorder`; applied to Browse, Memory Detail, Threads, and recovery panel. | Low; layout unchanged. |
| Buttons | Several custom buttons used raw `.white` and tertiary text as disabled fill. | One-off styling around primary and disabled states. | Use component tokens and `accentDisabled`. | Replaced raw foreground/fill usage; added reusable press style. | Low; action identifiers preserved. |
| Settings rows | Settings and Backup rows used generic `surface` while other screens moved to elevated surfaces. | Lists were not using the expanded surface hierarchy. | Use grouped background with elevated rows. | Moved Settings/Backup row backgrounds to `surfaceElevated`. | Low; native `List` behavior unchanged. |
| App Lock | Lock screen used general background and card surface. | Lock-specific tokens existed but were not fully applied. | App Lock should feel integrated and calm, not like a separate security product. | Used `appLockBackground`, `appLockSurface`, semantic foreground, and subtle border. | Low; auth logic unchanged. |
| MnemoLogoMark | Filled mark used legacy `primary` and raw white thread. | Logo predated expanded brand roles. | Logo should use brand-specific roles. | Updated filled/subtle/monochrome styles to brand/token roles. | Low; visual only. |
| Motion tokens | Only a few timing constants existed. | Motion was added ad hoc in screens. | Define restrained roles and keep Reduce Motion fallback. | Added `gentleSpring`, `emphasisSpring`, `fade`, `contentTransition`, `sheetTransition`, `scalePress`. | Low; no looping decorative motion added. |
| Press states | Many custom buttons/cards had no press feedback. | `.plain` button styles removed native feedback. | Add subtle feedback that does not feel toy-like. | Added `MnemoPressableButtonStyle` with Reduce Motion opacity fallback. | Low; button behavior unchanged. |
| App shell transitions | Root/overlay transitions did not account for Reduce Motion. | State animations used fixed animation. | Keep transitions subtle and respect accessibility settings. | App root, tab capture overlay, and capture menu use Reduce Motion-aware animation. | Low; no navigation rewrite. |
| Empty states | Empty states used mixed icon and card styles. | Older screens used generic surfaces. | Keep empty states light, instructional, and brand-adjacent. | Browse and chat landing now use memory/private/source tokens consistently. | Low. |
| Destructive actions | Delete buttons used legacy light red background. | Fixed token was not semantic. | Destructive actions should be visually separate but not alarming. | Memory detail delete uses `destructiveSoft` and `borderDestructive`. | Low; confirmation unchanged. |

## Guardrails

- No sign-up, Apple Sign In, backend auth, Foundation Models, MLX inference, cloud LLM, or autonomous behavior added.
- RecallEngine, persistence, App Lock authentication logic, backup behavior, and navigation architecture were not changed.
- Existing accessibility identifiers for simulator smoke testing were preserved.
