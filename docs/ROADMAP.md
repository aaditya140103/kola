# Kola — Implementation Roadmap

This roadmap builds Kola as a universal local reader without sacrificing interaction quality. Broad format support is delivered in controlled waves behind one document architecture.

## Phase 0 — Adaptive application foundation

### Goal

Create the cross-platform shell correctly before reader features multiply.

### Deliverables

- Flutter application for Linux, Windows, macOS, Android, and iOS
- Riverpod architecture
- go_router navigation
- Drift/SQLite
- structured local logging
- CI for format/analyze/test
- Kola design tokens
- `PlatformProfile`
- width/window classes
- `InputProfile`
- adaptive navigation primitives
- adaptive dialog/menu/sheet/text-field abstractions
- platform/system theme detection
- light/dark app shell
- reduced-motion and text-scale handling

### Exit criteria

The same product navigation works at compact, medium, expanded, large, and extra-large widths while using the appropriate interaction model for each platform.

---

## Phase 1 — Document engine foundation

### Goal

Build the universal document abstractions before accumulating format-specific UI.

### Deliverables

- `FormatRegistry`
- `DocumentAdapter`
- `FormatCapabilities`
- `KolaDocumentGraph`
- source locator model
- hybrid annotation anchor model
- document fingerprinting
- background job infrastructure
- graph/index cache versioning
- universal ReaderShell
- Fidelity/Flow view capability model

### Exit criteria

A sample adapter can provide metadata, semantic blocks, source mapping, search text, reading position, and annotation anchors without leaking parser-specific types into the app.

---

## Phase 2 — PDF fidelity reader

### Deliverables

- local PDF open
- PDFium/pdfrx adapter
- continuous pages
- single page
- two-page spread later in phase
- zoom/pan
- fit width/page
- outline
- thumbnails
- page search
- source text geometry
- position persistence
- desktop keyboard navigation
- mobile gestures

### Exit criteria

A long PDF can be read comfortably and resumed exactly.

---

## Phase 3 — Annotation core

### Deliverables

- highlight
- underline
- strikeout
- notes
- bookmarks
- semantic labels
- selection capsule
- annotation inspector
- annotation rail
- undo/redo
- source jump
- Markdown/JSON annotation export
- anchor repair/unresolved states

### Exit criteria

Annotations survive restart, zoom, resizing, theme changes, and supported representation changes.

---

## Phase 4 — Library + progress system

### Deliverables

- linked/managed files
- import/open-with/drag-drop
- duplicate detection
- cover/thumbnail cache
- Home / Continue Reading
- Library
- Collections
- Tags
- Favorites
- Unread / In Progress / Completed
- position progress
- actual reading coverage
- reading sessions/time
- completion thresholds
- subtle library progress UI

### Exit criteria

Jumping to the end changes position but does not falsely mark a document as read.

---

## Phase 5 — EPUB and native reflow formats

### Deliverables

- EPUB 2/3
- KEPUB where compatible
- HTML/XHTML
- Markdown
- TXT
- structured Flow renderer
- typography controls
- reader themes
- source-linked annotations
- local search

### Exit criteria

PDF and EPUB share the same library, progress, annotation, and search models.

---

## Phase 6 — Universal Flow Mode foundation

### Deliverables

- source-mapped graph rendering
- native/reconstructed/extracted/OCR flow-quality states
- source-preserving visual blocks
- switch Flow <-> Fidelity without losing position
- Flow annotations resolve back to source
- appearance panel
- content width/margins/line spacing/fonts/themes

### PDF reconstruction milestones

- word/glyph geometry
- line/block grouping
- reading order
- multi-column detection
- header/footer filtering
- headings/lists/quotes
- figure/table preservation

### Exit criteria

A well-formed digital PDF can be read and annotated in Flow Mode while remaining linked to the original pages.

---

## Phase 7 — Office text documents

### Deliverables

- DOCX first-class read support
- ODT
- RTF
- DOC through safe local legacy adapter/conversion where feasible
- Fidelity/layout representation where practical
- Flow Mode
- headings/lists/tables/images/footnotes
- search
- annotations
- progress/coverage

### Exit criteria

A Word-family document behaves like a Kola document, not a separate embedded viewer.

---

## Phase 8 — Presentations

### Deliverables

- PPTX
- ODP
- PPT through safe local legacy adapter/conversion where feasible
- slide thumbnails
- slide fidelity surface
- speaker notes
- slide/region annotations
- presentation Flow Mode
- search
- slide-based progress/coverage
- fullscreen presentation reading

---

## Phase 9 — Spreadsheets

### Deliverables

- XLSX
- XLSM read-only with macros never executed
- ODS
- CSV/TSV
- XLS/XLSB where maintainable local parsing exists
- virtualized sheet grid
- sheet tabs
- search
- range/cell annotations
- semantic table/range Flow Mode
- progress/coverage mapping

### Exit criteria

Large sheets remain responsive and readable without attempting to become a spreadsheet editor.

---

## Phase 10 — Ebook breadth

Add adapters in compatibility waves:

- MOBI
- AZW/AZW3 where unencrypted
- FB2/FBZ
- PRC
- PDB families
- PML/PMLZ
- LIT
- LRF
- RB
- SNB
- TCR
- CHM
- HTMLZ/TXTZ
- OEB/OPF packages
- DAISY/DTBook where practical

Rules:

- no DRM bypass;
- test each adapter against a legal corpus;
- advertise support status honestly;
- Flow Mode/search/progress are required for first-class status.

---

## Phase 11 — Comics, images, and fixed-layout breadth

### Deliverables

- CBZ
- CBR
- CB7
- CBC
- image folders
- DjVu
- XPS/OXPS
- manga RTL
- local OCR foundation
- OCR Flow Mode

---

## Phase 12 — Search and knowledge workflows

### Deliverables

- SQLite FTS index over KDG
- global search
- annotations/notes search
- command palette
- study-sheet export
- annotation links/backlinks
- copy quote with source metadata
- filtered exports

---

## Phase 13 — Advanced reading UX

### Deliverables

- Focus Mode
- Reading Lens
- Peek
- navigation back/forward history
- desktop document tabs
- crop margins
- persistent crop profiles
- customizable shortcuts
- full-screen/presentation reading

---

## Phase 14 — Ink and stylus

### Deliverables

- freehand ink
- pressure where available
- eraser
- lasso/move
- shapes/arrows
- text boxes
- finger-pan/stylus-draw separation
- source-aware export where supported

---

## Phase 15 — Theme and personalization expansion

Core theming exists earlier; this phase hardens customization.

### Deliverables

- custom app chrome themes
- custom reader themes
- semantic highlight remapping
- ambient solid/gradient/texture backgrounds
- local image backgrounds
- optional background blur
- theme import/export in local backup
- contrast safety checks

---

## Phase 16 — Platform-native polish pass

Audit each platform with users who actively use that OS.

### iOS/iPadOS

- navigation/back/sheets
- tab/sidebar adaptation
- selection
- safe areas
- keyboard/Pencil

### macOS

- menu bar
- toolbar/titlebar
- settings placement
- sidebar/inspector
- drag/drop
- shortcuts

### Android

- Material 3 behavior
- predictive back
- adaptive navigation
- foldables/tablets
- keyboard/mouse/stylus

### Windows

- titlebar/caption behavior
- navigation pane
- Fluent-style materials where appropriate
- snap/resizing
- pointer/keyboard workflows

### Linux

- window-manager integration
- GNOME/KDE sanity checks
- system theme/font
- desktop menus/context actions
- tiled/narrow windows

---

## Phase 17 — Accessibility and reading assistance hardening

- screen-reader audit
- keyboard audit
- large text
- high contrast
- reduced motion
- RTL
- dyslexia-friendly reader option
- local text-to-speech
- sentence/word tracking where available

---

## Phase 18 — Backup/export portability

- complete local backup
- restore
- annotation sidecars
- Markdown
- HTML
- JSON
- annotated PDF where technically supported
- portable theme/settings export
- migration documentation

---

## Phase 19 — Performance and robustness hardening

Benchmark and profile:

- 1,000-page PDF
- 500 MB image-heavy document
- large EPUB
- huge DOCX
- 500-slide presentation
- very large workbook
- thousands of annotations
- 10,000-document library
- OCR-heavy scans
- legacy ebook conversion corpus

Measure:

- cold/warm startup
- time to first readable content
- frame times
- memory
- cache behavior
- graph build speed
- indexing speed
- search latency
- Flow generation
- spreadsheet virtualization

## Engineering rule

Feature breadth never overrides reader correctness.

When choosing between adding another format and fixing selection, annotation anchors, input behavior, crashes, progress correctness, or reading performance, fix the core behavior first.