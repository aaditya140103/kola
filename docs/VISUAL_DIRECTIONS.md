# Kola — Visual Design Directions

This file defines three competing visual directions for Kola. They are intentionally not final. Each direction must be prototyped and tested using `UX_VALIDATION.md` before becoming the default visual system.

## Shared constraints across all directions

Every direction must preserve these Kola rules:

- document content remains visually dominant;
- low cognitive friction during long reading sessions;
- adaptive-native shell behavior by platform/window/input;
- app chrome theme remains separate from reader theme;
- strong accessibility and contrast;
- expressive styling is concentrated around interaction, not dense reading text;
- no decorative effect may reduce readability, selection accuracy, hit targets, or performance;
- Flow Mode, annotations, progress, search, and navigation keep identical semantics across directions.

## Direction A — Luminous Paper

### Intent

A premium, calm, contemporary reader with restrained translucent layering around an almost physical paper-like document surface.

### Personality

- premium
- quiet
- crafted
- modern
- tactile
- focused

### Visual language

- neutral or softly tinted workspace backgrounds;
- document surface appears brighter/clearer than surrounding chrome;
- subtle depth through borders, tonal separation, and soft shadows rather than heavy cards;
- restrained glass/translucency only for transient controls, top chrome, floating annotation tools, and sheets;
- medium-soft radii;
- sparse accent color;
- subtle ambient gradient or local background behind pages where enabled.

### Typography

- system UI font for shell;
- high-quality serif/sans reader typography controlled separately;
- moderate hierarchy, not oversized display typography everywhere;
- generous whitespace around library titles and reader metadata.

### Motion

- fluid but restrained;
- short blur/fade/scale for transient surfaces;
- spatial continuity when moving between library and reader;
- Flow/Fidelity transition feels like transforming the same object, not navigating to another app.

### Library

Covers are the strongest visual objects. Cards remain visually quiet.

```text
┌────────────────────────────────────────────────────────┐
│ Kola                          Search        + Import     │
│                                                        │
│ Continue reading                                       │
│                                                        │
│ ┌────────┐   ┌────────┐   ┌────────┐                  │
│ │ COVER  │   │ COVER  │   │ COVER  │                  │
│ │        │   │        │   │        │                  │
│ └────────┘   └────────┘   └────────┘                  │
│  Book name     Book name     Book name                 │
│  ━━━━━ 68%     ━━━ 42%       ━━━━━━━ 91%               │
└────────────────────────────────────────────────────────┘
```

### Reader

Document surface is visually isolated from chrome. Toolbars dissolve when inactive.

### Best fit

- premium reading product;
- books and long documents;
- users who value calm focus;
- strongest cross-platform premium identity.

### Risks

- excessive glass can hurt contrast/performance;
- too much neutrality can feel generic;
- needs excellent spacing and typography to avoid appearing empty.

---

## Direction B — Editorial Scholar

### Intent

A typographically strong, editorial reading environment inspired by modern magazines, research tools, publishing systems, and high-end print design.

### Personality

- intelligent
- confident
- editorial
- sophisticated
- information-rich
- timeless

### Visual language

- strong typographic hierarchy;
- deliberate grid structure;
- crisp separators;
- less reliance on shadows;
- occasional large editorial headings in the library/home screen;
- restrained but richer color blocks for sections, tags, and progress;
- rectangular surfaces with modest radii;
- strong alignment and whitespace rhythm.

### Typography

- typography carries more identity than effects;
- platform-native shell font remains default for controls;
- Kola may use an editorial display role for large non-system headings where appropriate;
- reader typography remains user-controlled.

### Motion

- precise and restrained;
- directional transitions;
- less spring/elastic motion than Direction A or C;
- emphasis on continuity and clear hierarchy.

### Library

Feels closer to a modern digital publication shelf than a file manager.

```text
KOLA / YOUR LIBRARY

Continue Reading
─────────────────────────────────────────────────────────
[cover]  The Design of Everyday Things        68%   2h left
[cover]  Deep Learning                        42%   5h left
[cover]  Research Methods                     91%   18m left

Recently Annotated
─────────────────────────────────────────────────────────
...
```

### Reader

- crisp sidebars;
- strong content hierarchy;
- excellent for citations, notes, tables, research papers, and long text;
- annotations can appear as editorial marginalia.

### Best fit

- students;
- researchers;
- professionals;
- heavy document users;
- users who value information clarity over playful styling.

### Risks

- can feel serious or academic to casual readers;
- requires outstanding typography to feel premium;
- less visually playful for younger audiences if used alone.

---

## Direction C — Soft Expressive

### Intent

A younger, friendlier and more expressive system with more color, rounded geometry, dynamic accents, playful but controlled motion, and highly personal themes.

### Personality

- energetic
- friendly
- personal
- expressive
- approachable
- contemporary

### Visual language

- softly rounded surfaces;
- stronger accent colors;
- dynamic color/theme support;
- bolder progress and selection states;
- colorful semantic annotation system becomes part of visual identity;
- occasional tonal cards and soft gradients;
- less empty than Direction A;
- more visual feedback around actions.

### Typography

- system UI typography;
- slightly stronger weight contrast;
- more prominent headings and progress states;
- still conservative inside document content.

### Motion

- expressive but short;
- highlight application may have a subtle sweep/settle;
- annotation creation has a small tactile response;
- mode switches can use spring motion;
- haptics on supported mobile devices;
- reduced-motion mode fully supported.

### Library

Library can use personalized backgrounds, dynamic accent colors, and friendlier grouping.

```text
Good evening
Pick up where you left off

╭─────────────────────────────╮
│ [cover]  Atomic Habits      │
│          68% read           │
│          Continue  →        │
╰─────────────────────────────╯

Your library
[cover] [cover] [cover] [cover]
```

### Reader

Reader itself remains calm; expressive language appears mainly in controls, selection, progress, theme picker, annotation tools, and transitions.

### Best fit

- younger audiences;
- casual readers;
- students;
- users who value personalization;
- mobile-heavy usage.

### Risks

- can become visually noisy if too many surfaces are colorful;
- can age faster as trends change;
- must not let playful motion interfere with long-form reading.

---

# Recommended hypothesis to test

Do **not** choose one direction purely by taste.

The strongest product hypothesis is a hybrid:

> **Luminous Paper as the structural base + Editorial Scholar typography/grid discipline + Soft Expressive interaction feedback and personalization.**

This hybrid should be treated as **Direction D — Kola Core** during testing, not assumed to be correct automatically.

## Direction D — Kola Core candidate

### Stable reading layer

From Luminous Paper:

- calm document-first workspace;
- restrained depth;
- premium surfaces;
- subtle translucency only around controls;
- low visual complexity.

### Information hierarchy

From Editorial Scholar:

- strong typographic hierarchy;
- disciplined grids;
- clean annotation/sidebar structure;
- high-density desktop layouts when appropriate.

### Delight layer

From Soft Expressive:

- dynamic themes;
- colorful semantic annotations;
- tactile micro-interactions;
- expressive progress/mode transitions;
- personalization.

The rule is:

```text
Reading content = calm
Navigation = familiar
Information = structured
Actions = expressive
Personalization = rich
```

# Design tokens to validate

Do not lock exact values until prototypes are tested, but begin with these roles.

## Color roles

```text
surface.canvas
surface.workspace
surface.panel
surface.floating
surface.document
surface.documentWarm
text.primary
text.secondary
text.muted
border.subtle
accent.primary
accent.hover
accent.pressed
focus.ring
annotation.important
annotation.definition
annotation.evidence
annotation.question
annotation.idea
annotation.review
```

Use semantic roles rather than raw colors in widgets.

## Spacing rhythm

Start with a 4 px base unit and prefer multiples:

```text
4 / 8 / 12 / 16 / 24 / 32 / 48 / 64
```

Dense desktop controls may use the smaller end; touch layouts should use the larger end.

## Radius roles

```text
radius.small
radius.control
radius.panel
radius.floating
radius.sheet
```

Do not make every object a pill.

## Elevation/depth roles

Use tonal contrast and borders before shadow.

```text
depth.flat
depth.raised
depth.floating
depth.modal
```

## Motion roles

```text
motion.instant
motion.fast
motion.standard
motion.emphasized
motion.pageTransform
```

Exact durations/curves must follow platform convention and reduced-motion settings.

# Components that establish Kola identity

These should receive the most visual design attention:

1. Library document card / row
2. Continue Reading hero
3. Reader chrome
4. Flow/Fidelity mode switcher
5. Selection annotation capsule
6. Semantic highlight palette
7. Annotation rail
8. Reading progress/coverage control
9. Appearance/theme panel
10. Search result card
11. Peek preview
12. Reading Lens
13. Command palette
14. Sync status surface

# Prototype set required before locking the visual system

Each serious direction should prototype at least these screens:

1. Desktop library
2. Desktop reader
3. Phone library
4. Phone reader
5. Annotation selection state
6. Appearance/theme customization

Do not evaluate a direction from one hero mockup only.

# Comparative UX test

Use `UX_VALIDATION.md`.

Recommended initial design comparison:

- A — Luminous Paper
- B — Editorial Scholar
- C — Soft Expressive
- D — Kola Core hybrid

Measure:

- first-impression attractiveness;
- VisAWI-S visual aesthetics;
- UEQ-S pragmatic + hedonic quality;
- task success for opening/resuming/highlighting/changing mode;
- time to find key controls;
- perceived reading comfort;
- willingness to use daily;
- preference after 10–20 minutes of actual reading, not only first glance.

# Selection rule

Do not simply pick the design with the highest first-glance rating.

Choose the direction with the strongest combined profile across:

```text
Aesthetic appeal
+ task success
+ discoverability
+ reading comfort
+ platform familiarity
+ accessibility
+ long-session preference
```

A design that wins the first 10 seconds but loses after 20 minutes of reading is not the right default for Kola.
