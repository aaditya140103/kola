# Kola — Evidence-Based UI/UX Research

Research snapshot: September 2026.

This document defines the scientific and standards-based foundation for Kola's visual and interaction design. It is intentionally separate from `UX_SPEC.md`: this file explains **why** design rules exist; `UX_SPEC.md` explains **what** to build.

## 1. Design thesis

Kola should be attractive enough to create an immediate positive emotional response, familiar enough to be understood instantly, and quiet enough to support long reading sessions.

The target is not maximal decoration. The target is:

> **Low cognitive friction + strong visual craftsmanship + selective expressiveness + native familiarity.**

The document is the primary content. Kola's personality appears around the content, not on top of it.

## 2. Evidence hierarchy

Not every design idea has the same level of support. Agents and designers should classify design decisions by evidence level.

### Level A — Standards and accessibility requirements

Examples:

- WCAG contrast/target/focus requirements;
- platform accessibility requirements;
- keyboard/screen-reader semantics;
- safe-area and system-gesture behavior.

These are defaults unless a stronger platform requirement exists.

### Level B — Replicated or peer-reviewed human-factors/HCI evidence

Examples:

- visual-complexity and first-impression research;
- aesthetics/usability relationship;
- reading line-length studies;
- validated UX/aesthetic measurement instruments.

Use these to shape defaults, then validate in Kola's actual context.

### Level C — Current platform conventions

Examples:

- Apple Human Interface Guidelines;
- Android/Material guidance;
- Windows Fluent guidance;
- GNOME HIG.

These determine native presentation and interaction expectations.

### Level D — Visual trends

Examples:

- glass/material effects;
- expressive motion;
- dynamic color;
- oversized typography;
- floating toolbars;
- gradient/ambient backgrounds.

Trends may be used only when they support hierarchy, emotion, or interaction. Never promote a trend above readability, accessibility, or familiarity.

## 3. What the research says about attractiveness

### 3.1 First impressions happen extremely quickly

Lindgaard et al. found that visual appeal judgments were already stable at very short exposures, including 50 ms.

Tuch et al. later found that **visual complexity** and **prototypicality/familiarity** affect aesthetic judgment within tens of milliseconds. Low visual complexity and high prototypicality produced the strongest appeal in their website experiments.

Kola implication:

- the first frame must feel ordered before the user reads labels;
- avoid crowded top bars, excessive cards, random colors, and competing surfaces;
- use familiar reader/library structures;
- differentiate Kola through refinement and interaction, not unfamiliar information architecture.

References:

- https://doi.org/10.1080/01449290500330448
- https://doi.org/10.1016/j.ijhcs.2012.06.003

### 3.2 Beautiful interfaces can feel easier to use — but bad usability eventually damages beauty

Tractinsky et al. showed a strong relationship between perceived aesthetics and perceived usability. Later controlled work showed the relationship is not one-way: frustrating usability can reduce post-use aesthetic ratings.

Kola implication:

- visual polish earns initial trust;
- actual interaction quality must confirm the promise;
- no animation, glass, or visual novelty may add extra steps or hide controls;
- design reviews must measure both aesthetics and task performance.

References:

- https://doi.org/10.1016/S0953-5438(00)00031-X
- https://www.sciencedirect.com/science/article/pii/S0747563212000908

### 3.3 Aesthetics is multi-dimensional

The VisAWI research identifies four useful facets of perceived visual aesthetics:

1. **Simplicity** — unity, order, clarity, balance.
2. **Diversity** — enough variation to avoid monotony.
3. **Colorfulness** — quality and composition of color.
4. **Craftsmanship** — how deliberately and professionally elements fit together.

Kola implication:

A "minimal" interface is not automatically attractive. Kola should balance simplicity with controlled diversity and visibly high craftsmanship.

Reference:

- https://doi.org/10.1016/j.ijhcs.2010.05.006

## 4. Kola's visual strategy

### 4.1 Calm canvas, expressive moments

The reader surface should be quiet. Expressiveness appears mainly when the user acts.

Quiet zones:

- document body;
- reading canvas;
- long-form annotation text;
- Flow Mode typography;
- search result reading context.

Expressive moments:

- applying a highlight;
- switching Fidelity <-> Flow;
- opening a book;
- progress completion;
- dragging/resizing a panel;
- choosing a theme;
- entering Focus Mode;
- successful sync completion;
- command palette appearance;
- selection capsule.

This follows the modern direction seen in Material 3 Expressive while preserving the reading-first nature of the product.

References:

- https://design.google/library/design-notes-material-3-expressive-liam-spradlin
- https://blog.google/products-and-platforms/platforms/android/material-3-expressive-android-wearos-launch/

### 4.2 Brand through identity, not repeated decoration

Kola's identity should primarily come from:

- app icon;
- distinctive but restrained accent system;
- Kola-specific reader controls;
- animation timing and tactile response;
- typography hierarchy;
- highlight palette;
- theme/background system;
- empty-state artwork or abstract motifs;
- polished spatial rhythm.

Avoid filling every control with a brand color. Apple's current branding guidance explicitly recommends using brand color intentionally rather than broadly and keeping familiar platform patterns.

Reference:

- https://developer.apple.com/design/human-interface-guidelines/branding

## 5. Visual hierarchy rules

### 5.1 One dominant object per state

Each screen/state should have one obvious primary visual object:

- Library Home -> Continue Reading or library content;
- Reader -> document;
- Search -> query/results;
- Annotation review -> annotation stream;
- Settings -> current settings section.

No screen should contain multiple equally loud focal elements.

### 5.2 Use space before decoration

Prefer hierarchy through:

1. position;
2. spacing;
3. size;
4. typography weight;
5. contrast;
6. container shape;
7. color;
8. motion.

Do not start with color or shadow when spacing/alignment can communicate the hierarchy.

Apple's layout guidance emphasizes reading order, alignment, and progressive disclosure; Windows guidance similarly uses geometry, layout, elevation, and hierarchy.

References:

- https://developer.apple.com/design/human-interface-guidelines/layout
- https://learn.microsoft.com/en-us/windows/apps/design/guidelines-overview

### 5.3 Progressive disclosure

Show the minimum controls needed for the current reading state. Less-used functionality moves into:

- context menus;
- bottom sheets;
- inspectors;
- secondary panels;
- command palette;
- overflow menus.

Critical/high-frequency actions must remain directly accessible.

This reduces visual complexity without reducing capability.

## 6. Gestalt-style perceptual rules

Treat these as perceptual design heuristics, not magic laws.

### Proximity

Items that belong together should be physically closer than unrelated items.

Application:

- highlight color + annotation action cluster;
- progress percentage + progress bar;
- reader typography controls grouped separately from app appearance controls.

### Similarity

Same visual treatment implies same role.

Application:

- all secondary toolbar actions use one hierarchy;
- semantic highlight types use stable icon/label treatment;
- clickable cards do not visually match passive information panels.

### Common region

Use containers sparingly to communicate a real grouping.

Application:

- search filters;
- theme preview collections;
- annotation inspector.

Avoid "card soup" where every row becomes a card.

### Continuity and alignment

Consistent alignment makes content faster to scan.

Application:

- library metadata baselines;
- annotation quote/note alignment;
- settings labels and controls;
- toolbar icon grid.

## 7. Choice and action complexity

### 7.1 Reduce simultaneous choices

Hick-Hyman-style choice effects are a useful design heuristic: as the number/uncertainty of choices grows, decision time can increase.

Kola implication:

- do not show all annotation tools at once on phones;
- show 4–6 high-frequency selection actions and move the rest under More;
- theme chooser should show curated presets first, advanced editor second;
- import flow should not ask every possible storage/sync option up front.

### 7.2 Make frequent actions physically easy

Fitts-style target acquisition principles imply that larger, closer targets are easier to acquire.

Kola implication:

- primary touch actions should use generous hit areas;
- toolbars should place high-frequency actions near natural pointer/thumb regions;
- floating annotation actions should appear near selection without covering it;
- tiny icons may be visually small but need larger invisible hit areas.

Platform baseline:

- Android/Material recommends at least 48dp touch targets.
- WCAG 2.2 AA requires at least 24x24 CSS px or sufficient separation for web targets; Kola should exceed this on touch devices.

References:

- https://developer.android.com/develop/ui/compose/accessibility/api-defaults
- https://www.w3.org/TR/WCAG22/

## 8. Typography and reading science

### 8.1 Reading width

A controlled screen-reading study by Dyson & Haselgrove found a medium line length around 55 characters effective for comprehension and reading speed in their conditions.

WCAG AAA visual-presentation guidance requires a mechanism allowing blocks of text to be no wider than 80 characters/glyphs (40 CJK), among other controls.

Kola default Flow Mode target:

- normal prose target: roughly 50–70 characters per line;
- default around the mid-50s to low-60s where font/script permits;
- user-adjustable width;
- never force one value across all scripts, fonts, or accessibility settings.

Reference:

- https://doi.org/10.1006/ijhc.2001.0458
- https://www.w3.org/TR/WCAG22/#visual-presentation

### 8.2 Typography hierarchy

Use a small, intentional type scale. Too many weights/sizes reduce coherence.

UI body text should generally follow the platform system font for native legibility. Kola may use a distinctive display face selectively for branding or headings if accessibility behavior is preserved.

References:

- https://developer.apple.com/design/human-interface-guidelines/typography
- https://developer.gnome.org/hig/guidelines/typography.html

### 8.3 Reader typography is user-controlled

Flow Mode must expose:

- font family;
- font size;
- line height;
- paragraph spacing;
- content width;
- margins;
- theme/background;
- optional hyphenation;
- alignment where appropriate.

Reading comfort varies strongly by language, vision, display, context, and task. Defaults should be evidence-informed, not rigid.

## 9. Color and contrast

### 9.1 Contrast is a hard floor

Kola should meet or exceed WCAG-style contrast targets for custom-rendered UI:

- normal text: 4.5:1 minimum;
- large text: 3:1 minimum;
- meaningful non-text UI boundaries/states: 3:1 minimum.

Reference:

- https://www.w3.org/TR/WCAG22/

### 9.2 Semantic color beats literal color

Use semantic roles:

- primary action;
- destructive;
- warning;
- success;
- selected;
- surface;
- text primary/secondary;
- annotation categories.

Platform colors should adapt to system appearance where relevant. Avoid hard-coded platform colors.

Reference:

- https://developer.apple.com/design/human-interface-guidelines/color

### 9.3 Color is not the only signal

Every semantic annotation/category/state also needs one or more of:

- icon;
- label;
- shape;
- position;
- pattern.

This is both an accessibility and comprehension rule.

## 10. Dark mode and reading backgrounds

Dark mode is not a simple inversion.

Kola must independently tune:

- surface luminance;
- text luminance;
- highlight colors;
- selection colors;
- images/illustrations;
- separators;
- focus indicators.

Respect system appearance in app chrome by default, while keeping the reader theme independently selectable because long-form reading is a special context.

Reference:

- https://developer.apple.com/design/human-interface-guidelines/dark-mode

## 11. Depth, blur, glass, and materials

Depth should explain hierarchy, not advertise the rendering engine.

### Allowed

- floating selection capsule;
- transient command palette;
- top/bottom reader chrome;
- inspector/popup separation;
- platform-native material effects;
- subtle background blur where it improves context continuity.

### Avoid

- glass behind long text;
- nested translucent cards;
- blur on every panel;
- low-contrast glass controls;
- expensive effects that harm scrolling.

Apple's 2026 Liquid Glass guidance explicitly says to keep it as a functional controls/navigation layer and avoid using it throughout the content layer.

Reference:

- https://developer.apple.com/design/human-interface-guidelines/materials

## 12. Motion and haptics

Motion must communicate one of:

- cause/effect;
- spatial relationship;
- hierarchy;
- state transition;
- completion;
- continuity.

No perpetual decorative animation in the reader.

Recommended motion character:

- short and responsive for tool actions;
- spring-like only for tactile direct manipulation;
- gentler shared-axis/fade for navigation;
- no large motion for routine text selection;
- honor reduced-motion settings.

On Android, predictive-back behavior should remain visible and compatible with system navigation rather than being overridden by a custom gesture.

Reference:

- https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back

## 13. Native familiarity across platforms

### Apple platforms

Current guidance emphasizes:

- content-first presentation;
- standard familiar components;
- selective brand color;
- Liquid Glass for functional navigation/control layers;
- system typography and Dynamic Type behavior;
- platform-appropriate sheets, navigation, menu structures.

### Android

Current direction emphasizes:

- edge-to-edge content;
- Material 3 Expressive where appropriate;
- dynamic/personal color;
- responsive components;
- tactile motion/haptics;
- predictive back;
- 48dp touch targets.

### Windows

Current Fluent direction emphasizes:

- effortless;
- calm;
- personal;
- familiar;
- clear geometry, layout, materials, motion, and navigation.

### Linux/GNOME

GNOME emphasizes:

- simplicity;
- reduced user effort;
- progressive disclosure;
- system typography;
- adaptive breakpoints;
- avoiding excessive custom styling;
- responsiveness across narrow and wide windows.

References:

- https://developer.apple.com/design/human-interface-guidelines/branding
- https://developer.android.com/design/ui/mobile/guides/layout-and-content/edge-to-edge
- https://learn.microsoft.com/en-us/windows/apps/design/design-principles
- https://developer.gnome.org/hig/principles.html
- https://developer.gnome.org/hig/guidelines/adaptive.html

## 14. Cognitive accessibility is good mainstream UX

Kola should make key actions easy to find and keep repeated navigation predictable.

Use:

- stable locations for high-frequency actions;
- familiar icons + labels where ambiguity exists;
- clear headings/regions;
- consistent navigation order;
- visible orientation/progress;
- undo instead of unnecessary confirmation dialogs where safe;
- concise interface writing.

References:

- https://www.w3.org/WAI/WCAG2/supplemental/objectives/o1-understandable/
- https://www.w3.org/WAI/WCAG2/supplemental/objectives/o2-find/
- https://www.w3.org/WAI/WCAG22/Understanding/consistent-navigation

## 15. Kola aesthetic scorecard

Every major screen should be reviewed against these eight dimensions:

1. **Clarity** — can the structure be understood immediately?
2. **Simplicity** — does everything feel unified and ordered?
3. **Craftsmanship** — are alignment, typography, states, and spacing polished?
4. **Distinctiveness** — is there enough Kola personality to be memorable?
5. **Color quality** — is color intentional rather than merely plentiful?
6. **Content dominance** — does the document remain the main visual object?
7. **Native familiarity** — does it behave like the host platform?
8. **Accessibility** — does the visual system remain usable under accessibility settings?

A screen that scores high in visual novelty but low in clarity/content dominance is rejected.

## 16. Anti-patterns

Do not ship:

- card-on-card dashboards;
- gradients on every surface;
- blur/glass behind reading text;
- 8+ equally prominent toolbar actions on phone;
- hidden primary actions available only through gestures;
- tiny controls with tiny hitboxes;
- low-contrast gray-on-gray "premium" styling;
- animation that delays an action;
- novel navigation purely for branding;
- inconsistent icon styles;
- excessive font families/weights;
- random per-screen spacing;
- forced dark mode;
- a reader canvas that visually competes with its document.

## 17. Sources used for this evidence base

Primary/standards/platform sources:

- ISO 9241-210: https://www.iso.org/standard/77520.html
- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- Apple HIG: https://developer.apple.com/design/human-interface-guidelines/
- Android adaptive/UI guidance: https://developer.android.com/design/ui/mobile/
- Windows design: https://learn.microsoft.com/en-us/windows/apps/design/
- GNOME HIG: https://developer.gnome.org/hig/

Empirical HCI/aesthetics:

- Lindgaard et al. (2006), DOI: 10.1080/01449290500330448
- Tuch et al. (2012), DOI: 10.1016/j.ijhcs.2012.06.003
- Tractinsky et al. (2000), DOI: 10.1016/S0953-5438(00)00031-X
- Moshagen & Thielsch (2010), DOI: 10.1016/j.ijhcs.2010.05.006
- Moshagen & Thielsch (2013), DOI: 10.1080/0144929X.2012.694910
- Dyson & Haselgrove (2001), DOI: 10.1006/ijhc.2001.0458

Measurement:

- SUS: Brooke (1996)
- UEQ-S: https://ueq-online.org/
- VisAWI-S: DOI 10.1080/0144929X.2012.694910
- NASA-TLX: https://www.nasa.gov/human-systems-integration-division/nasa-task-load-index-tlx/

## 18. Final rule

A design claim is never justified by saying only "this looks modern."

For meaningful UI changes, document at least one of:

- evidence-backed usability/readability rationale;
- accessibility requirement;
- platform convention;
- measured user preference;
- deliberate branded/hedonic goal that does not degrade the above.
