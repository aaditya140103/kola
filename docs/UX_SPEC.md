# Kola — UI/UX Specification

## 1. Design goal

Kola should feel modern in 2026 without depending on visual novelty that harms reading. The UI should be **quiet, spatial, responsive, and highly contextual**.

The document is the product. Controls are supporting actors.

## 2. Visual language

### Kola Surface System

Use three visual layers:

1. **Document surface** — the page/reflow content.
2. **Workspace surface** — sidebars, tabs, search and annotation panels.
3. **Floating controls** — selection actions, tool palettes, command palette and transient controls.

Floating controls may use subtle translucency/blur when the platform handles it efficiently, but never at the cost of legibility or GPU performance.

Avoid excessive glass effects behind dense text.

### Shape

- medium-soft corners rather than extreme pill shapes everywhere;
- pills only for compact actions, filters and segmented controls;
- panels should feel integrated rather than like floating cards stacked everywhere.

### Motion

Motion communicates hierarchy and location.

Use:

- short fade/scale for contextual controls;
- shared-axis transitions between library and reader where practical;
- spring-like panel movement with restrained overshoot;
- page/reader motion that respects platform physics;
- reduced-motion mode.

No decorative perpetual animations.

## 3. Adaptive shell

### Wide desktop (> 1200 logical px)

```text
┌─────────────────────────────────────────────────────────────────────┐
│ tabs / document title                              search  controls │
├─────────────┬──────────────────────────────────────┬────────────────┤
│             │                                      │                │
│ TOC /       │              DOCUMENT                │  annotations / │
│ thumbnails  │                                      │  notes/search  │
│             │                                      │                │
└─────────────┴──────────────────────────────────────┴────────────────┘
```

Both side panels can be resized and collapsed.

### Medium/tablet

One docked panel maximum. Secondary panels become overlays.

### Phone

Reader becomes almost fully edge-to-edge.

- top controls appear on tap/scroll-up;
- bottom reader controls appear on tap;
- TOC/search/annotations use bottom sheets or full-height sheets;
- Flow Mode is one tap away;
- selection controls remain close to selected content.

## 4. Library screen

### Desktop

Left navigation rail/sidebar:

- Home
- All Documents
- Recent
- Favorites
- Collections
- Tags
- Annotated

Primary toolbar:

- search;
- sort;
- filter;
- grid/list toggle;
- import.

Document card:

- cover thumbnail;
- title;
- author;
- reading progress;
- subtle format indicator only when useful;
- last opened.

Do not cover cards with action buttons. Secondary actions appear on hover or context menu.

### Home

Home emphasizes continuation, not file management.

Sections:

- Continue Reading
- Recently Added
- Recently Annotated
- Favorites

## 5. Reader top bar

The top bar should contain only high-frequency navigation and view actions.

Suggested desktop order:

```text
Back | Sidebar | Document Title | [flex space] | Search | View Mode | Annotate | More
```

The annotation toolbar is not permanently expanded unless the user pins it.

On phone the title may collapse to maximize width.

## 6. Reader sidebars

### Left panel tabs

- Outline / TOC
- Thumbnails
- Bookmarks

### Right panel tabs

- Annotations
- Search Results
- Document Info

On desktop these can be keyboard toggled.

## 7. Selection UX

Selecting text is one of Kola's most important interactions.

### Default selection capsule

Immediately after selection, show:

```text
[ ● ] [Highlight] [Note] [Copy] [Tag] [⋯]
```

`●` displays the active semantic color. Pressing it expands the palette.

### Fast mode

When Auto Highlight is enabled, selecting text applies the current highlight immediately. A tiny undo affordance appears briefly.

### Touch

Use native-feeling drag handles and generous touch targets. The action capsule should avoid obscuring the selected line.

## 8. Annotation tools

Desktop/tablet can use a compact vertical floating tool dock:

- select;
- highlight;
- underline;
- pen;
- eraser;
- text note;
- area selection;
- shape;
- undo/redo.

The dock can be moved to left/right and pinned/unpinned.

Phone should expose the same tools through a compact bottom palette rather than shrinking desktop controls.

## 9. Flow Mode UI

Flow Mode should feel like entering a premium reading environment, not converting the file into a web page.

Typography panel:

- font family;
- font size;
- line height;
- paragraph spacing;
- content width;
- alignment when appropriate;
- theme;
- optional hyphenation;
- reset.

At the top or bottom, a subtle control allows instant return to original pages at the equivalent source position.

Figures and tables that cannot be safely reflowed are rendered as source-preserving blocks with a “View on page” action.

## 10. Reading themes

Built-in document themes:

- Paper
- Warm
- Dark
- OLED Black
- Low Contrast Night

Application chrome theme is independent:

- System
- Light
- Dark

Custom reader theme can be added after v1.

## 11. Focus Mode

Trigger by toolbar, command palette or keyboard shortcut.

When active:

- sidebars close;
- tabs/toolbars disappear;
- page centers;
- pointer can auto-hide;
- tapping/moving pointer reveals minimal navigation;
- Esc exits on desktop.

Optional Reading Lens remains available.

## 12. Search UX

### In-document search

A compact panel shows:

- query;
- result count;
- next/previous;
- snippets;
- section/page.

Results should highlight transiently on the page without becoming stored annotations.

### Global search

Command palette and Library search can search the entire local corpus.

Results grouped by:

- Documents
- Annotations
- Notes
- Body matches

Each result includes enough context to understand why it matched.

## 13. Peek previews

Preview surfaces should be temporary and preserve reading continuity.

Desktop:

- hover after a short intentional delay or click a preview affordance.

Touch:

- press-and-hold or explicit preview button.

Peek is useful for:

- footnotes;
- citations;
- internal page links;
- figures;
- annotation links.

## 14. Tabs and history

Desktop supports document tabs.

Each tab preserves:

- reading position;
- active mode;
- zoom;
- panel state.

Internal jumps create navigation history separate from tabs.

Back means “return to where I was before this jump,” not necessarily “close document.”

## 15. Command palette

`Ctrl/Cmd + K`

Visual design:

- centered floating surface;
- immediate keyboard focus;
- fuzzy command search;
- shortcut shown at right;
- recent commands below empty query.

Categories should not be visually noisy. Search first, taxonomy second.

## 16. Keyboard interaction

Recommended defaults:

- `Ctrl/Cmd + O` — Open document
- `Ctrl/Cmd + F` — Search current document
- `Ctrl/Cmd + K` — Command palette
- `Ctrl/Cmd + L` — Library
- `Ctrl/Cmd + Shift + F` — Search library
- `B` — Bookmark current location when reader has focus
- `H` — Highlight selection / toggle highlight tool depending context
- `N` — Add note to selection
- `[` / `]` — toggle left/right panel
- `Esc` — dismiss transient UI / exit Focus Mode
- `+` / `-` — zoom or font size depending reader mode

All single-key shortcuts should be disabled while typing into text fields.

Every shortcut must be discoverable in menus/settings.

## 17. Touch and gesture interaction

### PDF page mode

- pinch to zoom;
- double tap to smart zoom;
- drag to pan when zoomed;
- tap center to toggle controls;
- page swipe in paged mode.

### Reflow mode

- normal scroll;
- edge tap optional page-like navigation;
- text selection behaves like modern native readers.

Gesture customization can come later; avoid shipping many hidden gestures initially.

## 18. Stylus behavior

When a stylus is detected where supported:

- pen can draw without switching the whole reader into a different application mode;
- finger continues to pan by default;
- stylus button/eraser maps to erase when platform APIs expose it;
- stroke smoothing must be subtle and configurable later.

## 19. Empty and error states

### Empty library

Do not show a dashboard full of disabled UI.

Show:

- large “Open a book” action;
- drop target on desktop;
- supported formats;
- one sentence explaining that files remain local.

### Unsupported Flow Mode

Do not say only “Error.”

Explain:

> This document's layout could not be safely reflowed. You can keep reading in Page Mode.

Optionally describe the detected reason.

### Missing linked file

Preserve metadata/annotations and offer:

- Locate File
- Remove From Library

Never delete annotations just because the source path disappeared.

## 20. Accessibility UX

- every icon-only control has an accessible label and tooltip;
- focus order follows visual order;
- keyboard focus is visibly distinct from hover;
- annotation semantics are not communicated by color alone;
- minimum touch targets follow platform accessibility guidance;
- text scales without clipping controls;
- reader contrast is user adjustable;
- motion honors reduced-motion preference.

## 21. What Kola should avoid

- permanent giant toolbars;
- dashboard card overload;
- excessive gradients;
- glass blur beneath reading text;
- hidden critical actions available only through gestures;
- modal dialogs for routine reader actions;
- forcing users to organize before they can read;
- forcing a proprietary library format;
- separate inconsistent annotation systems for PDF and EPUB;
- copying mobile UI directly onto desktop.

## 22. UX quality bar

Before a feature is considered complete, verify it with all four input models where applicable:

1. mouse/trackpad;
2. keyboard;
3. touch;
4. stylus.

And verify at three form factors:

1. phone;
2. tablet/small desktop;
3. wide desktop.

The interaction may adapt, but the capability and mental model should remain consistent.