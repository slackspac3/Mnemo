# Mnemo External Colour Research

Date: 2026-07-10

## Scope and evidence boundary

This note supplements the official Apple design study with external visual and design-system references requested during the identity review.

External trend articles are used for inspiration and market context. They do not override Apple Human Interface Guidelines, accessibility requirements, installed SDK behavior, or Mnemo's semantic design tokens.

## Source assessment

### Design+Code iOS Colors

[Design+Code's iOS Colors chapter](https://designcode.io/ios-design-handbook-ios-colors/) is an iOS 14-era primer rather than current platform authority. Its durable guidance is still useful:

- neutral tones should occupy most of the interface and defer attention to content
- color should emphasize actions and highlighted states rather than decorate every surface
- red should retain destructive meaning and green should retain success meaning
- system and dynamic colors are preferable for platform surfaces and labels
- dark mode needs a designed tonal hierarchy rather than a simple inversion

Its recommendation to begin with a vibrant pastel is not a good fit for Mnemo. The product needs long-session reading comfort, evidence clarity, and trust more than visual exuberance.

### Octet mobile UI palettes

[Octet's mobile UI palette collection](https://octet.design/colors/user-interfaces/mobile-ui-design/) is useful as a broad mood board. It classifies many image-derived palettes and exposes categories such as calming, dark UI, monochromatic, technology, and accessibility-focused.

It does not provide enough visible methodology, semantic-role mapping, adaptive light/dark behavior, or contrast evidence to choose production UI colors directly. A five-color image palette is not yet an application color system.

Use Octet only to identify candidate relationships and emotional territory. Every selected color still needs mapping to canvas, content surface, text, action, evidence, focus, and semantic state roles.

### Envato 2026 mobile color trends

[Envato's 2026 trend roundup](https://elements.envato.com/learn/color-scheme-trends-in-mobile-app-design) identifies dark interfaces with bright accents, accessibility-led contrast, gradients, duotone, minimalist systems, warm nature palettes, muted jewel tones, and soft-tech pastels.

The relevant signals for Mnemo are:

- restrained neutral foundations remain current
- muted sapphire, Prussian blue, and other controlled jewel tones can feel polished without becoming loud
- accessibility and deliberate contrast are being treated as visual quality, not a constraint added later
- small palettes make primary actions and content hierarchy clearer

The less suitable signals are:

- expressive gradients compete with memory text and source evidence
- soft lavender and bluish-purple pastels reinforce the generic AI appearance the redesign is trying to leave
- pervasive beige, sand, sage, and terracotta can shift Mnemo toward wellness, lifestyle, or journaling conventions
- neon accents on dark surfaces are too theatrical for a private memory product

Envato's examples are marketplace templates, so their trend ranking is directional rather than product evidence.

### Acorn iOS color system

[Mozilla's Acorn iOS color system](https://acorn.firefox.com/latest/mobile/styles/color/i-os-WVfl69Hz-WVfl69Hz) demonstrates a production-grade distinction between layered neutral surfaces and purpose-specific accent roles. It also assigns a separate accent to private browsing rather than allowing privacy color to redefine the whole interface.

Mnemo implication: privacy is a product property, not a reason to tint every control purple. Privacy status should use a compact badge, label, or symbol while the rest of the UI remains content-led.

### Adobe accessibility guidance

[Adobe's color accessibility guidance](https://www.adobe.com/express/learn/blog/color-accessibility-guide) recommends a small role-based palette, redundant labels and icons, and three fast validation views: grayscale, small-screen, and color-vision simulation.

These become explicit Mnemo review gates. A candidate palette fails even if its individual contrast ratios pass when:

- primary action, source evidence, and privacy status become indistinguishable in grayscale
- an accent loses legibility at toolbar or caption size
- success, warning, and destructive states are recognizable only by hue
- dark-mode surfaces collapse into one plane

### Apple semantic color guidance

[Apple's current color guidance](https://developer.apple.com/design/human-interface-guidelines/color) remains authoritative for implementation. System surfaces and labels should use dynamic semantic roles, and the application must not redefine the meaning of system colors.

## Findings for Mnemo

### The rejected palette's problem is allocation, not only hue

The current system gives indigo responsibility for:

- brand identity
- primary actions
- selected navigation
- focus
- privacy badges
- source evidence
- Local AI and Sense presentation

This makes the interface coherent but semantically flat. The eye sees purple everywhere and cannot infer why a purple element matters.

The cream canvas also occupies nearly every screen, while content surfaces are only slightly lighter. The result is warm but visually muddy and too close to beige-led journaling products.

### Contemporary does not mean gradient-heavy

The strongest intersection between the external research and Apple's content-first guidance is:

- near-neutral adaptive canvases
- stable opaque reading surfaces
- one restrained, muted jewel-tone action accent
- a distinct evidence/source accent
- semantic state colors reserved for state
- color applied to a small percentage of the screen

This can feel current without imitating generic glassmorphism, marketplace templates, or AI pastels.

## Direction decision

### Advance: Mineral Recall

Mineral Recall remains the strongest next prototype:

| Role | Light | Dark |
| --- | --- | --- |
| Canvas | `#F3F4F5` | `#111416` |
| Content surface | `#FAFBFC` | `#1C2023` |
| Primary text | `#1B1D20` | `#F1F3F4` |
| Secondary text | `#5D6268` | `#B5BBC0` |
| Action/focus | `#315A78` | `#82B4D2` |
| Source evidence | `#8A4D38` | `#E29A78` |
| Success | `#26734D` | `#63C99A` |
| Warning | `#8A5B00` | `#F0B95C` |
| Destructive | `#B3261E` | `#FF8A83` |

Why it advances:

- muted mineral blue aligns with the refined-jewel-tone direction without looking like generic system blue
- neutral gray canvases remove the beige cast
- clay adds warmth specifically to source evidence instead of tinting the whole product
- blue, clay, green, amber, and red remain distinguishable by both hue and role
- light and dark modes feel related without being literal inversions

Implementation refinement:

- prefer platform semantic background and label roles where they give the correct hierarchy
- use fixed brand values for the mark and carefully controlled action/source tokens
- keep most navigation and secondary toolbar symbols monochrome
- use source clay only for evidence relationships, not arbitrary decoration
- do not color memory types; keep type recognition symbolic and textual
- under Reduce Transparency, replace tinted materials with opaque semantic surfaces

### Hold: Quiet Juniper

Quiet Juniper remains a valid alternative, but teal is strongly associated with health, wellness, sustainability, and privacy products. It also sits close to Mnemo's semantic success green. It would need stricter structural differentiation and risks becoming another fashionable muted-green interface.

### Reject: Warm Archive

Warm Archive is emotionally distinctive but the cranberry action accent sits too close to destructive red, and its neutral foundation retains some of the warmth the user already rejected. It is better suited to an editorial archive or lifestyle journal than a trust-first recall tool.

## Required prototype matrix

Before production adoption, Mineral Recall must be rendered on real Mnemo screens:

- empty Recall
- populated Recall with answer and source evidence
- Memories list, search, and filter state
- Memory Detail
- capture review and correction confirmation
- onboarding
- App Lock
- Settings

Each screen needs light, dark, Increased Contrast, Reduce Transparency, grayscale, and at least one color-vision simulation. The palette should be accepted only after the source relationship remains clearer than the brand accent on actual content.

