# Kola — UI/UX Specification

> The detailed cross-platform rules live in [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md). This document defines Kola's product-level interaction model.

## 1. UX goal

Kola should feel like **the same excellent reader made specifically for each device**.

It must be:

- consistent in terminology and capability;
- native-feeling in navigation and interaction;
- document-first;
- calm rather than dashboard-heavy;
- powerful without exposing every control at once;
- equally usable with touch, mouse, keyboard, and stylus where those inputs exist.

The document is the product. Chrome is temporary support.

## 2. Consistency model

Kola does **not** mean pixel-identical UI across platforms.

Consistent everywhere:

- Library
- Search
- Collections
- Flow Mode
- Fidelity View
- Focus Mode
- annotation semantics
- progress model
- reading coverage
- bookmarks
- source-linked annotations
- theme concepts
- document state

Adaptive per platform:

- navigation bar/sidebar/rail;
- title/window chrome;
- menus;
- dialogs;
- sheets;
- scrolling;
- text selection;
- back behavior;
- haptics;
- visual density;
- keyboard/menu integration;
- hover and right-click behavior.

## 3. Window-size model

Kola responds to available window width rather than hardcoded device names.

```text
Compact      < 600 dp
Medium       600–839 dp
Expanded     840–1199 dp
Large        1200–1599 dp
Extra Large  >= 1600 dp
```

The layout can change while the app is running because of resizing, split screen, folding, rotation, Stage Manager, snapping, or external displays.

## 4. Top-level application structure

```text
Kola
├─ Home
├─ Library
├─ Search
├─ Collections
└─ Reader Workspace
```

Tags, Favorites, Annotated, Unread, In Progress, and Completed behave as library filters/views rather than bloating top-level navigation.

Settings follow platform conventions and are not a permanent top-level desktop destination.

## 5. Library navigation

### Compact

Use bottom navigation:

```text
Home | Library | Search | Collections
```

### Medium

Use a navigation rail or platform-equivalent adaptive sidebar.

### Expanded and above

Use a persistent leading navigation surface and list/detail layouts where useful.

The navigation representation can change while preserving the currently selected destination.

## 6. Home

Home should answer one question first:

> What do I want to continue reading?

Recommended structure:

1. Continue Reading
2. Recently Added
3. Recently Annotated
4. Favorites

Avoid filling Home with statistics, promotional cards, empty widgets, or secondary settings.

## 7. Library

Library views:

- cover grid;
- list;
- compact table on desktop.

Document card priorities:

1. cover/thumbnail;
2. title;
3. author/source;
4. subtle reading progress;
5. status/last opened.

Secondary actions appear through hover/context menu on pointer devices or long-press/more menu on touch.

## 8. Universal reader shell

The Reader Workspace consists of:

```text
Reader Workspace
├─ Document Surface
├─ View Switcher
├─ Structure Navigation
├─ Annotation Inspector
├─ Search
├─ Progress
└─ Contextual Controls
```

The same shell hosts PDFs, ebooks, Word documents, presentations, spreadsheets, comics, and other supported formats.

## 9. Universal view switcher

When multiple representations exist, Kola presents a small, consistent switcher.

Examples:

```text
PDF      Original | Flow
DOCX     Layout   | Flow
PPTX     Slides   | Flow
XLSX     Sheet    | Flow
EPUB     Book     | Flow
Comic    Pages    | OCR Flow
```

The wording is format-aware but the concept is identical: **source/fidelity representation versus optimized reading representation**.

## 10. Phone reader

Target default state is immersive.

Current Phase 2 behavior keeps reader controls visible above a fully expanded document surface. Narrow toolbars wrap instead of overflowing; tapping/selecting source content does not hide Back. Immersive auto-hide will return with an explicit, tested Focus Mode control and reliable touch/keyboard escape (see the reader audit). This is an interim usability repair, not a change to the long-term immersive-reader goal.

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

One tap reveals compact controls:

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

Secondary tools open as platform-native-feeling sheets:

- Contents
- Search
- Annotations
- Appearance
- Document Info

The Library bottom navigation disappears while reading.

## 11. Tablet reader

Tablet uses available space for one supporting pane when useful.

Examples:

```text
┌─────────────┬────────────────────────────┐
│ Contents    │                            │
│             │          DOCUMENT          │
│             │                            │
└─────────────┴────────────────────────────┘
```

or:

```text
┌────────────────────────────┬─────────────┐
│                            │ Annotations │
│          DOCUMENT          │             │
│                            │             │
└────────────────────────────┴─────────────┘
```

Both side panes should not open by default merely because the tablet is wide.

Stylus annotation gets a compact movable palette.

## 12. Desktop reader

Wide layout:

```text
┌────────────────────────────────────────────────────────────────────┐
│ document tabs/title                              reader commands  │
├───────────────┬───────────────────────────────┬────────────────────┤
│ Contents      │                               │ Annotations        │
│ Thumbnails    │          DOCUMENT             │ Notes              │
│ Bookmarks     │                               │ Search             │
│               │                               │                    │
└───────────────┴───────────────────────────────┴────────────────────┘
```

Rules:

- both panes optional;
- both panes resizable;
- pane size remembered;
- hover reveals secondary actions;
- right-click is supported;
- drag/drop is first-class;
- commands expose keyboard shortcuts;
- tabs support multiple open documents;
- toolbars stay compact.

## 13. Platform profiles

### iPhone

- iOS navigation/back conventions;
- bottom tab navigation in library;
- native-feeling sheets/popovers;
- edge swipe where appropriate;
- safe-area-aware edge-to-edge reader;
- iOS selection behavior;
- system font and tint conventions.

### iPadOS

- adaptable sidebar/tab navigation;
- list-detail library on large windows;
- supporting inspector pane in reader;
- strong Pencil/stylus behavior;
- collapse cleanly in split screen/Stage Manager.

### macOS

- toolbar/sidebar/inspector model;
- app menu bar;
- standard settings/preferences placement;
- native window controls;
- keyboard-heavy workflows;
- right-click and hover;
- drag/drop;
- system font/accent conventions.

### Android

- Material 3 interaction model;
- bottom navigation in compact library;
- rail/drawer for wider windows;
- predictive/system back support;
- edge-to-edge layouts;
- bottom sheets for compact reader tools;
- adaptive support for foldables/tablets;
- keyboard/mouse/stylus support on capable devices.

### Windows

- standard window/caption behavior;
- Fluent-inspired desktop presentation;
- navigation pane/sidebar;
- visible desktop scrollbars;
- mouse/keyboard density;
- context menus;
- snap/resizing-friendly panes;
- file drag/drop;
- system typography.

### Linux

Linux has no single universal design language. Kola should use:

- native/window-manager decorations where possible;
- system font/theme preference;
- desktop shortcuts;
- visible scrollbars;
- right-click;
- drag/drop;
- compact header/toolbar;
- resizable panes;
- no imitation of Windows or macOS chrome.

Kola can align more closely with GNOME conventions on GNOME-like environments without making GNOME-specific behavior mandatory for other desktops.

## 14. Selection and annotation UX

Text selection is one of the most important interactions in Kola.

### Pointer devices

Selection opens a compact capsule:

```text
[Color] [Highlight] [Note] [Copy] [Tag] [More]
```

Keyboard accelerators remain active.

### Touch

Use native-feeling text selection handles and a Kola action bar/sheet positioned so it does not cover the selected passage.

### Auto Highlight

When enabled, valid selection creates a highlight immediately using the current semantic style. A lightweight Undo affordance appears.

### Stylus

Where pointer type can be distinguished reliably:

- stylus draws/annotates;
- finger pans/navigates;
- eraser/button behavior maps to platform capability.

## 15. Annotation tools

Domain-specific tool set:

- Select
- Highlight
- Underline
- Strikeout
- Pen
- Eraser
- Text note
- Area selection
- Shape
- Arrow
- Text box
- Undo
- Redo

Desktop/tablet can use a movable compact palette. Phone uses a bottom palette/sheet.

## 16. Flow Mode UX

Flow Mode should feel like a purpose-built reading environment, not a conversion preview.

Appearance controls:

- font family;
- text size;
- line height;
- paragraph spacing;
- content width;
- margins;
- column count when useful;
- alignment where appropriate;
- hyphenation;
- reader theme;
- page/background color;
- ambient background.

Source-preserving blocks expose **View in original**.

Switching between Flow and Fidelity should preserve the equivalent source location.

## 17. Word/document Flow Mode

DOCX/ODT/RTF Flow Mode should favor reading structure over editor chrome:

- title;
- headings;
- paragraphs;
- lists;
- footnotes;
- tables;
- figures;
- comments where supported.

No ribbon-like editing UI is necessary because Kola is not a word processor.

## 18. Presentation UX

Fidelity View:

```text
[slide thumbnails] [current slide] [notes/annotations]
```

Flow Mode:

```text
Presentation title
Slide 1 — title
Text blocks
Figure
Speaker notes

Slide 2 — title
...
```

Progress naturally maps to slides while reading coverage captures genuinely viewed slides/content.

## 19. Spreadsheet UX

Fidelity View uses a virtualized sheet/grid surface.

Important controls:

- sheet tabs;
- cell/range search;
- zoom;
- range highlighting;
- comments/annotations;
- freeze information where parsed.

Flow Mode converts the selected sheet/table/region into an accessible reading sequence rather than forcing horizontal scrolling.

## 20. Reading progress UX

Kola distinguishes two metrics.

### Position

Where the user currently is.

Examples:

- 63%
- page 188/300
- chapter 14/22
- slide 31/64

### Coverage

How much content was actually meaningfully viewed.

Expanded progress panel:

```text
Position          63%
Actually read     48%
Reading time      3h 42m
Estimated left    ~2h 10m
Status            In Progress
```

Do not over-gamify reading by default.

Library cards show one subtle primary progress indicator; deeper statistics require an intentional action.

## 21. Themes and backgrounds

Four independent layers:

```text
System appearance
App chrome theme
Reader theme
Ambient background
```

Built-in app themes:

- System
- Light
- Dark
- OLED Black
- Soft Gray
- Warm Neutral

Built-in reader themes:

- Paper
- Warm Paper
- Sepia
- Soft Gray
- Sage
- Night
- Low-Contrast Night
- OLED Black

Ambient backgrounds:

- solid color;
- gradient;
- subtle texture;
- local image;
- blurred local image.

User customization must never compromise minimum readable contrast without a warning/reset path.

## 22. Focus Mode

Focus Mode removes almost all interface chrome.

- sidebars close;
- toolbar hides;
- pointer can hide on desktop;
- minimal position appears on demand;
- annotation shortcuts remain available;
- Reading Lens remains available;
- Escape exits on desktop;
- tap gesture reveals controls on touch.

## 23. Reading Lens

Optional movable focus region:

- one line;
- several lines;
- paragraph;
- horizontal ruler.

Surrounding material can be dimmed rather than blurred for performance/accessibility.

## 24. Annotation Rail

When the annotation inspector is closed, subtle edge markers indicate annotations without reducing document width.

- hover previews on pointer devices;
- tap opens preview on touch;
- keyboard can jump next/previous annotation.

## 25. Peek

Peek previews references without losing current position.

Use for:

- footnotes;
- citations;
- internal document links;
- figures;
- tables;
- slides;
- annotation links.

Desktop uses hover/click affordance. Touch uses long press or explicit preview action.

## 26. Search

### Current document

Compact search panel:

- query;
- count;
- next/previous;
- snippets;
- page/chapter/slide/sheet context.

### Global

Library/command search groups results by:

- Documents
- Annotations
- Notes
- Body content

Results always jump to a resolvable source location.

## 27. Command palette

Desktop/tablet: `Ctrl/Cmd + K`.

Commands:

- Open document
- Search library
- Search current document
- Go to page/chapter/slide/sheet
- Toggle Flow Mode
- Toggle Focus Mode
- Add bookmark
- Change theme
- Change highlight style
- Open annotations
- Export
- Settings

Search-first, keyboard-first, no visually heavy taxonomy.

## 28. Keyboard

Default examples:

- `Ctrl/Cmd + O` — Open
- `Ctrl/Cmd + F` — Search document
- `Ctrl/Cmd + Shift + F` — Search library
- `Ctrl/Cmd + K` — Command palette
- `B` — Bookmark current location
- `H` — Highlight selection/tool
- `N` — Note
- `[` — Toggle leading pane
- `]` — Toggle trailing pane
- `Esc` — Dismiss / leave Focus Mode
- `+` / `-` — Zoom or text size according to mode

Single-key shortcuts are inactive while typing.

Platform-standard equivalents override generic mappings when appropriate.

## 29. Menus and context actions

Desktop actions should be discoverable through:

- platform application/menu bar where appropriate;
- toolbar;
- context menu;
- command palette;
- shortcut.

Mobile should not hide essential actions behind context menus requiring long press.

## 30. Motion

Use motion for:

- hierarchy;
- continuity;
- feedback.

Do not use decorative perpetual motion.

Platform navigation/sheet/dialog motion follows host expectations. Kola-specific transitions may be used for Flow/Fidelity switching, focus mode, and annotation creation.

Always honor reduced motion.

## 31. Empty state

Empty library should be simple:

- Open a document
- drag/drop target on desktop
- supported-format summary
- statement that files remain local

No fake dashboard.

## 32. Error states

Failures should preserve reading whenever possible.

Examples:

- Flow reconstruction imperfect -> show Fidelity View and explain limitations;
- indexing failed -> document still opens;
- linked source missing -> Locate File;
- annotation temporarily unresolved -> preserve annotation and expose repair state;
- parser unsupported -> explain whether preview/conversion is available.

## 33. Accessibility

From the first implementation:

- platform accessibility semantics;
- keyboard traversal;
- visible focus;
- scalable text;
- high contrast;
- reduced motion;
- non-color annotation labels;
- RTL;
- screen-reader labels;
- appropriate touch target sizes;
- Flow Mode optimized for reflow/accessibility.

## 34. UX anti-patterns

Kola should avoid:

- one pixel-identical UI on every operating system;
- desktop UI squeezed onto mobile;
- phone UI stretched onto desktop;
- permanent giant toolbars;
- dashboard card overload;
- excessive glass/gradients behind text;
- critical gesture-only actions;
- modal dialogs for routine reading actions;
- separate annotation mental models by file format;
- dozens of visible buttons just because a desktop has space;
- hiding desktop functionality behind touch-first bottom sheets;
- changing Kola terminology between platforms.

## 35. Quality bar

Every core flow should be tested with:

- iPhone compact;
- Android compact;
- foldable/medium Android;
- iPad split view;
- iPad full width;
- macOS narrow/wide;
- Windows snapped/wide;
- Linux tiled/wide.

And with:

- touch;
- mouse/trackpad;
- keyboard;
- stylus where applicable;
- light/dark;
- large text;
- reduced motion;
- RTL.

A feature is not finished merely because it works on the developer's primary device.