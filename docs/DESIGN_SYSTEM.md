# Kola — Adaptive Native Design System

## 1. Design thesis

Kola uses **one product language with platform-native presentation**.

The app must feel recognizably like Kola on every platform while also respecting the conventions of iOS, iPadOS, macOS, Android, Windows, and Linux desktops.

The rule is:

> **Keep meaning, hierarchy, document behavior, and terminology consistent. Adapt navigation, chrome, density, interaction, system integration, motion, and control presentation to the host platform and available window size.**

Kola must never ship a desktop interface squeezed onto a phone, an Android interface copied onto iOS, or a mobile interface enlarged for desktop.

## 2. What remains identical everywhere

These are Kola product semantics and should not move conceptually between platforms:

- Library
- Search
- Collections
- Continue Reading
- Reader
- Fidelity View
- Flow Mode
- Focus Mode
- annotation meanings
- highlight semantic labels
- reading progress
- reading coverage
- bookmarks
- table of contents / structure navigation
- annotation list
- document information
- theme concepts
- keyboard command names
- document state and source anchors

The same action must have the same icon family meaning and wording even when the actual platform glyph changes.

Examples:

```text
Highlight = same concept everywhere
Search = same concept everywhere
Flow Mode = same concept everywhere
Annotation panel = same concept everywhere
```

## 3. What adapts by platform

The following are implementation/presentation details and should follow platform expectations:

- system font
- navigation container
- top bar / title bar
- context menus
- dialogs
- sheets/popovers
- back navigation
- scroll physics
- scrollbars
- text selection handles
- selection menus
- haptics
- hover behavior
- right-click behavior
- keyboard accelerators
- menu bar integration
- window controls
- safe areas
- system accent colors
- touch target sizing
- visual density
- default motion curves

## 4. Do not identify layout from device names

Kola should primarily respond to **available window size and input capability**, not assumptions such as `isTablet` or `isDesktop`.

A desktop window can be narrow. A tablet can have a desktop-sized floating window. A foldable can change size while the app is running.

Recommended Kola width classes:

```text
Compact      < 600 dp
Medium       600–839 dp
Expanded     840–1199 dp
Large        1200–1599 dp
Extra Large  >= 1600 dp
```

These are layout policies, not device categories.

## 5. Kola's canonical app structure

The app has two major environments:

```text
Kola
├─ Library Workspace
│  ├─ Home
│  ├─ Library
│  ├─ Search
│  └─ Collections
│
└─ Reader Workspace
   ├─ Document Surface
   ├─ Structure/Navigation
   ├─ Annotations
   ├─ Search
   └─ Reading Controls
```

Settings are not a primary navigation destination on desktop. They live in the standard platform settings/preferences location and remain accessible from mobile menus.

## 6. Primary navigation by width

### Compact

Use a bottom tab/navigation bar in the **Library Workspace**.

Recommended destinations:

```text
Home | Library | Search | Collections
```

When a document opens, the reader becomes immersive and the library navigation disappears.

### Medium

Use a compact navigation rail or platform-equivalent adaptive sidebar.

Reader utility panels appear as temporary sheets/panes unless enough width exists.

### Expanded

Use a persistent leading navigation rail/sidebar in the library.

Reader may show one supporting pane alongside the document.

### Large / Extra Large

Use a persistent library sidebar and optionally richer list-detail layouts.

Reader can support:

```text
[Structure] [Document] [Annotations]
```

but both side panes remain independently collapsible.

## 7. Reader hierarchy

The document must visually dominate every form factor.

Priority order:

1. document content;
2. reading position/progress;
3. immediate navigation;
4. annotation actions;
5. document structure;
6. secondary metadata/settings.

Persistent toolbars must never consume significant reading space merely because room exists.

## 8. Phone reader

### Default state

```text
┌───────────────────────┐
│                       │
│                       │
│       DOCUMENT        │
│                       │
│                       │
│                       │
└───────────────────────┘
```

The reader is edge-to-edge where safe.

Tap once to reveal controls:

```text
┌───────────────────────┐
│ ‹  Document title  ⋯  │
│                       │
│       DOCUMENT        │
│                       │
│                       │
│  48% ━━━━━━━  Flow ✎ │
└───────────────────────┘
```

The lower bar should remain very compact. Complex controls open a bottom sheet.

### Reader sheets

- Contents
- Search
- Annotations
- Appearance
- Document info

Only one large sheet is active at a time.

## 9. Tablet reader

Tablet is not simply a larger phone.

Portrait/smaller window:

- document surface;
- one overlay/supporting pane;
- top toolbar;
- floating or bottom annotation palette.

Wide landscape/larger window:

```text
┌────────────┬─────────────────────────────┐
│ Structure  │                             │
│            │         DOCUMENT            │
│            │                             │
└────────────┴─────────────────────────────┘
```

or:

```text
┌─────────────────────────────┬────────────┐
│                             │ Annotation │
│         DOCUMENT            │ Inspector  │
│                             │            │
└─────────────────────────────┴────────────┘
```

Do not show both side panes automatically unless the width comfortably supports them.

## 10. Desktop reader

Recommended wide layout:

```text
┌──────────────────────────────────────────────────────────────────┐
│ window/title/tab region                         reader commands  │
├──────────────┬───────────────────────────────┬───────────────────┤
│ Contents     │                               │ Annotations       │
│ Thumbnails   │          DOCUMENT             │ Notes             │
│ Bookmarks    │                               │ Search            │
│              │                               │                   │
├──────────────┴───────────────────────────────┴───────────────────┤
│ optional subtle progress/status region                           │
└──────────────────────────────────────────────────────────────────┘
```

Rules:

- left and right panes resize independently;
- each pane can collapse completely;
- widths are remembered per user;
- drag/drop is first-class;
- hover reveals secondary actions;
- right click opens context actions;
- keyboard shortcuts cover all high-frequency commands;
- tooltips expose shortcut equivalents;
- document tabs are available when multiple files are open.

## 11. iPhone / iOS profile

Kola should use Apple interaction idioms:

- system typography;
- iOS-style navigation/back behavior;
- interactive edge-swipe back where appropriate;
- tab bar for compact top-level library navigation;
- native-feeling sheets and popovers;
- native-feeling text selection behavior;
- safe-area aware edge-to-edge content;
- minimal persistent reader chrome;
- system accent/tint behavior where it improves familiarity;
- haptics only where conventional and useful.

Do not make Android-style navigation components appear on iOS merely for visual consistency.

## 12. iPadOS profile

Use an adaptive sidebar/tab relationship for the library.

On wider windows:

- sidebar may remain visible;
- library can use list-detail layouts;
- reader can use supporting inspector panes;
- stylus/Apple Pencil annotation receives first-class interaction affordances.

On narrower Stage Manager/split-screen windows, automatically collapse back toward the compact interaction model.

## 13. macOS profile

Kola should feel like a serious document application.

Use platform conventions for:

- traffic-light window controls;
- title bar / toolbar organization;
- app menu bar;
- Preferences/Settings command placement;
- keyboard shortcuts;
- sidebar behavior;
- inspector-style annotation/details panes;
- right-click/context menus;
- hover affordances;
- drag and drop;
- system font and accent color.

The macOS toolbar should prioritize:

```text
Back | Sidebar | Document Title | Search | View | Annotate | More
```

Avoid phone-style bottom navigation on macOS.

## 14. Android profile

Use Material 3 behavior and Android system conventions while retaining Kola's identity.

### Compact window

- bottom navigation in library;
- edge-to-edge layouts;
- top app bar where orientation is needed;
- bottom sheets for reader secondary tools;
- system back/predictive back support;
- Material-native text fields, switches, menus, and touch feedback.

### Medium/expanded window

- navigation rail or drawer depending available width/content;
- supporting panes for list/detail and reader inspectors;
- stylus, keyboard, mouse and trackpad support on tablets/ChromeOS-class devices.

## 15. Windows profile

Kola should adopt Fluent-style desktop behavior without turning the whole product into a WinUI imitation.

Use:

- native titlebar/caption behavior;
- standard minimize/maximize/close expectations;
- system typography;
- navigation pane/sidebar patterns;
- familiar command/menu placement;
- mouse/keyboard-first density;
- visible draggable scrollbars;
- platform context menus;
- file drag/drop;
- snap/resizing-friendly responsive panes;
- Mica/Acrylic-like materials only where platform APIs and performance make them appropriate.

Primary commands should not be hidden behind touch-first bottom sheets when desktop space exists.

## 16. Linux profile

Linux does not have one universal native design language, so Kola should favor **desktop conventions over imitation of a specific toolkit**.

Default strategy:

- system/window-manager decorations where possible;
- system/default UI font where available;
- no forced Windows/macOS titlebar imitation;
- standard desktop keyboard shortcuts;
- visible draggable scrollbars;
- right-click menus;
- drag and drop;
- resizable sidebars;
- compact toolbar/header area;
- honor system light/dark preference;
- use system accent information when reliably available, otherwise use Kola accent.

On GNOME-like environments, Kola can lean toward headerbar/sidebar simplicity and progressive disclosure. On KDE-like environments, avoid assumptions that would conflict with normal window/menu behavior.

## 17. Kola visual identity

Kola should still be visually recognizable across every platform.

Shared elements:

- Kola logo and app icon;
- semantic annotation color system;
- document surface treatment;
- typography hierarchy roles;
- spacing rhythm;
- Flow Mode appearance panel;
- subtle rounded geometry;
- icon meanings;
- progress visualization;
- annotation rail;
- selection highlight language;
- focus/reading modes.

Kola identity should live primarily in the **content workspace**, not by replacing platform-standard system controls.

## 18. Typography

### Application UI

Use platform system fonts by default.

This improves:

- native feel;
- text metrics;
- localization;
- accessibility;
- performance;
- user familiarity.

Do not ship one branded UI font across all operating systems as the default.

### Reading content

Reader typography is independent from app UI typography.

Built-in reader families should include broad categories such as:

- System Serif
- System Sans
- Book Serif
- Humanist Sans
- Monospace
- Dyslexia-friendly optional face

Users may install/use local fonts when platform permissions permit.

## 19. Iconography

Use a semantic Kola icon abstraction:

```text
KolaIcon.back
KolaIcon.more
KolaIcon.search
KolaIcon.sidebar
KolaIcon.highlight
...
```

The resolver can provide a platform-appropriate glyph.

Examples:

- back chevron shape can differ on Apple vs Material platforms;
- overflow orientation can differ;
- platform-standard share/import/export symbols can differ.

Custom icons are reserved for Kola-specific concepts such as Flow Mode and Reading Lens.

## 20. Controls

Prefer native/adaptive presentation for controls with strong learned platform behavior:

- switches;
- toggles;
- text fields;
- date/time pickers if ever used;
- dialogs;
- menus;
- selection handles;
- context menus;
- scrollbars;
- progress indicators where system-like behavior matters.

Use custom Kola components for domain-specific controls:

- annotation capsule;
- highlight palette;
- Flow Mode switcher;
- Reading Lens control;
- Annotation Rail;
- reading progress/coverage presentation;
- document view selector.

## 21. Themes and backgrounds

### Separation

Never conflate:

```text
System appearance
App chrome theme
Reader theme
Ambient background
```

Example:

```text
System: Dark
Kola chrome: Dark
Reader: Warm Paper
Ambient: Deep Charcoal
```

### App chrome themes

- System
- Light
- Dark
- OLED Black
- Soft Gray
- Warm Neutral
- user custom

### Reader themes

- Paper
- Warm Paper
- Sepia
- Soft Gray
- Sage
- Night
- Low-Contrast Night
- OLED Black
- user custom

### Ambient backgrounds

- solid
- gradient
- subtle texture
- local image
- blurred local image

Reader legibility always overrides decorative backgrounds.

## 22. Progress UI

Progress must be useful without becoming gamified clutter.

### Reader

Default compact presentation:

```text
48%  ━━━━━━━━━━━━━━━
```

Expanded details on tap/hover:

```text
Position          63%
Actually read     48%
Chapter           14 / 22
Reading time      3h 42m
Estimated left    ~2h 10m
```

`Actually read` is reading coverage, not just the furthest location reached.

### Library cards

Use one subtle progress bar. Detailed metrics appear on hover/tap/details rather than filling every card with numbers.

## 23. Annotation UX

Text selection is the highest-frequency annotation path.

### Desktop

Compact floating capsule near selection:

```text
[Color] [Highlight] [Note] [Copy] [Tag] [More]
```

Keyboard accelerators work simultaneously.

### Touch

Use platform-native selection handles plus a compact Kola action strip/sheet that never obscures the selected text unnecessarily.

### Stylus

Stylus can annotate while finger remains navigation/pan input where platform APIs make reliable pointer-type distinction possible.

## 24. Motion

Motion conveys spatial continuity, not decoration.

Use platform-appropriate curves and durations for:

- navigation;
- pane appearance;
- sheets;
- dialogs;
- menus;
- drag interactions.

Kola-specific motion can be used for:

- Flow/Fidelity transition;
- focus mode;
- annotation creation;
- progress transitions.

Respect reduced-motion settings everywhere.

## 25. Density

### Touch

- larger targets;
- more spacing;
- fewer simultaneous commands.

### Pointer/keyboard

- denser lists;
- smaller but accessible controls;
- hover states;
- right-click;
- resizable panels;
- more commands visible simultaneously.

Do not globally shrink the mobile UI to create desktop density.

## 26. Input equivalence

Every core action must have a natural path for applicable inputs:

- touch;
- mouse/trackpad;
- keyboard;
- stylus.

Examples:

```text
Open annotation
Touch: tap rail marker
Mouse: click/hover marker
Keyboard: next-annotation shortcut
Stylus: tap marker
```

## 27. Reader-first progressive disclosure

The main reader should not display every capability simultaneously.

Always visible only when necessary:

- content;
- basic position/progress.

One interaction away:

- navigation;
- search;
- Flow/Fidelity toggle;
- annotation entry;
- appearance.

Two interactions away:

- export;
- document metadata;
- advanced annotation settings;
- detailed statistics;
- parser/Flow diagnostics.

## 28. Native integration checklist

### All platforms

- open-with integration;
- file picker conventions;
- share/import integration where supported;
- system theme;
- accessibility APIs;
- clipboard;
- platform keyboard mappings;
- safe areas/window insets;
- local notification-free reading by default.

### Desktop

- drag/drop;
- recent files where platform integration permits;
- file manager reveal;
- multi-window considered later;
- standard menus and shortcuts;
- system window management.

### Mobile/tablet

- share sheet/open-in;
- edge-to-edge;
- orientation/window resizing continuity;
- system back/navigation conventions;
- keyboard/stylus support when attached.

## 29. Accessibility baseline

- platform accessibility semantics;
- scalable text;
- full keyboard traversal on desktop/tablet;
- high contrast;
- reduced motion;
- non-color annotation labels;
- minimum touch target guidance;
- screen-reader labels for icon-only actions;
- focus states distinct from hover;
- Flow Mode optimized for accessible reflow;
- RTL-aware layout and reading order.

## 30. Implementation architecture for adaptive UI

Use semantic component interfaces instead of direct platform branching throughout the widget tree.

Conceptually:

```text
KolaAdaptiveScaffold
KolaAdaptiveNavigation
KolaAdaptiveToolbar
KolaAdaptiveDialog
KolaAdaptiveMenu
KolaAdaptiveSheet
KolaAdaptiveScrollbar
KolaAdaptiveTextField
KolaAdaptiveSelectionUI
```

Each component reads:

```text
PlatformProfile
WindowClass
InputProfile
AccessibilityProfile
DocumentCapabilities
```

and chooses the correct implementation.

This keeps platform adaptation centralized and testable.

## 31. PlatformProfile

Conceptual model:

```text
PlatformProfile
 - operatingSystem
 - preferredDesignLanguage
 - systemBrightness
 - systemAccent
 - supportsHover
 - supportsRightClick
 - hasPhysicalKeyboard
 - hasStylus
 - pointerKinds
 - windowClass
 - reducedMotion
 - highContrast
 - textScale
```

Do not cache assumptions that can change at runtime, especially window size, attached input devices, theme, or accessibility preferences.

## 32. Design quality tests

Every important screen should be validated in at least these states:

- iPhone compact portrait
- iPhone landscape
- Android compact portrait
- Android foldable/medium
- iPad split view
- iPad full width
- macOS narrow window
- macOS wide window
- Windows narrow snap layout
- Windows wide desktop
- Linux narrow tiled window
- Linux wide desktop

And with:

- touch only;
- mouse/trackpad;
- keyboard;
- stylus where relevant;
- light;
- dark;
- high text scale;
- reduced motion;
- RTL language.

## 33. Final design rule

When product consistency conflicts with a deeply learned platform convention:

1. preserve Kola's meaning and user data model;
2. follow the platform's interaction convention;
3. retain Kola identity through content styling and domain-specific controls;
4. never sacrifice reader usability merely to make all screenshots look identical.

Kola should feel like **the same excellent reader made specifically for each device**, not the same screenshot rendered on every device.