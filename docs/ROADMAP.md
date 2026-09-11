# Kola — Implementation Roadmap

This roadmap optimizes for a strong reader core first. Do not start by implementing every format or every visual effect.

## Phase 0 — Foundation

### Goal

A stable cross-platform Flutter shell with project conventions in place.

### Deliverables

- Flutter app boots on Linux, Windows, macOS, Android and iOS targets.
- Adaptive app shell.
- Kola design tokens.
- light/dark app theme.
- Riverpod state architecture.
- go_router navigation.
- Drift/SQLite database setup.
- structured local logging.
- basic settings persistence.
- CI for formatting, analyze and tests.

### Exit criteria

The same source tree builds on all target platforms with no product features yet.

---

## Phase 1 — PDF reading MVP

### Goal

Make Kola an excellent basic PDF reader before adding library complexity.

### Deliverables

- open local PDF;
- PDFium/pdfrx adapter;
- continuous page view;
- single-page view;
- zoom/pan;
- fit width / fit page;
- page navigation;
- current page indicator;
- table of contents/outline where available;
- thumbnails;
- in-document text search;
- remember reading position;
- desktop keyboard navigation;
- mobile gestures;
- dark application shell.

### Exit criteria

A user can comfortably read a long PDF, quit Kola, reopen it and resume exactly where they stopped.

---

## Phase 2 — Annotation core

### Goal

Build the annotation model correctly before broadening formats.

### Deliverables

- hybrid AnnotationAnchor model;
- highlight;
- underline;
- text note;
- bookmark;
- annotation colors and semantic labels;
- contextual selection toolbar;
- annotation side panel;
- annotation filtering;
- persistent undo/redo for session actions;
- jump from annotation to source;
- database migration tests;
- export annotations to Markdown and JSON.

### Exit criteria

Annotations survive restart, zoom changes and normal document navigation reliably.

---

## Phase 3 — Library

### Goal

Turn the reader into a local document workspace.

### Deliverables

- import/open file;
- drag and drop desktop import;
- linked vs managed file handling;
- document fingerprinting and duplicate detection;
- metadata extraction;
- cover/thumbnail generation;
- grid/list views;
- Continue Reading;
- Recent;
- Favorites;
- reading status;
- collections;
- tags;
- document details;
- missing-file recovery.

### Exit criteria

A library containing hundreds of documents remains fast and easy to navigate.

---

## Phase 4 — EPUB and reflowable documents

### Goal

Prove the normalized document architecture with a second major format.

### Deliverables

- EPUB adapter;
- EPUB metadata/cover;
- chapter navigation;
- reflow renderer;
- typography controls;
- reader themes;
- EPUB highlight/underline/note anchors;
- EPUB search;
- Markdown reader;
- TXT reader;
- local HTML reader.

### Exit criteria

PDF and EPUB share the same library, annotation panel, tags and export UX despite different rendering engines.

---

## Phase 5 — Flow Mode for PDF

### Goal

Create Kola's signature source-mapped PDF reading mode.

### Milestone A — extraction

- extract text and glyph/word geometry;
- normalize whitespace;
- identify lines;
- identify text blocks;
- source-map every extracted range.

### Milestone B — reading order

- detect columns;
- order blocks;
- detect repeated header/footer candidates;
- preserve captions;
- identify figures/tables that should remain as visual source blocks.

### Milestone C — semantic reflow

- heading detection;
- paragraph grouping;
- lists;
- quotations;
- source-preserving image/table blocks.

### Milestone D — annotation mapping

- highlight in Flow Mode;
- resolve to source page geometry;
- highlight created in Page Mode appears in Flow Mode;
- preserve reading location while switching modes.

### Milestone E — user controls

- font;
- size;
- line height;
- spacing;
- width;
- theme;
- reset.

### Exit criteria

A clean, digitally generated academic PDF with one or two columns can be read and annotated in Flow Mode without losing the connection to the original pages.

### Important scope rule

Do not claim that every PDF is safely reflowable. Fall back to Page Mode when confidence is low.

---

## Phase 6 — Search and knowledge workflows

### Goal

Make annotations useful after reading.

### Deliverables

- SQLite full-text index;
- background indexing;
- library-wide search;
- annotation/note search;
- tags in search;
- command palette;
- study sheet generation from selected annotations;
- annotation backlinks;
- copy quote with source metadata;
- export filtered annotations.

### Exit criteria

A user can find a phrase across thousands of indexed pages and jump directly back to the source.

---

## Phase 7 — Advanced reading UX

### Deliverables

- Focus Mode;
- Reading Lens;
- Annotation Rail;
- Peek for footnotes/internal links;
- navigation back/forward history;
- document tabs on desktop;
- crop margins;
- persistent crop profiles;
- two-page spread;
- RTL spread;
- presentation/fullscreen mode;
- customizable keyboard shortcuts.

---

## Phase 8 — Ink and stylus

### Deliverables

- freehand strokes;
- pressure data where available;
- eraser;
- lasso/select/move strokes;
- shape tool;
- arrows;
- text box;
- finger-pan/stylus-draw separation;
- export ink into annotated PDF where supported.

---

## Phase 9 — Comics and additional formats

### Deliverables

- CBZ;
- CBR;
- manga RTL behavior;
- image folders;
- DOCX read-only adapter;
- DjVu investigation/adapter.

Do not let low-quality DOCX conversion delay the core reader.

---

## Phase 10 — Accessibility and reading assistance expansion

These requirements begin earlier, but this phase hardens them.

### Deliverables

- screen-reader audit;
- full keyboard audit;
- large text audit;
- reduced motion;
- high-contrast themes;
- improved RTL;
- local text-to-speech using platform voices;
- word/sentence tracking where platform APIs allow.

---

## Phase 11 — Export, backup and portability hardening

### Deliverables

- complete local library backup;
- restore workflow;
- annotation sidecar export/import;
- Markdown templates;
- HTML export;
- annotated PDF export where supported;
- portable app-data migration documentation.

---

## Phase 12 — Performance hardening

### Test corpus

Benchmark:

- 1,000-page text PDF;
- image-heavy textbook;
- multi-column paper;
- 500 MB PDF;
- 2,000-book metadata library;
- 10,000-book metadata library;
- document with thousands of annotations;
- large EPUB.

### Measure

- cold/warm startup;
- time to first page;
- scroll frame times;
- memory use;
- page cache hit/miss behavior;
- indexing speed;
- database query latency;
- Flow Mode extraction time.

Do not optimize based on assumptions; profile first.

---

# Suggested first public release

A credible **Kola 1.0** does not need every item above.

Recommended 1.0 scope:

- PDF + EPUB + TXT + Markdown;
- excellent PDF Page Mode;
- EPUB/reflow reader;
- highlights, underlines, notes and bookmarks;
- local library;
- collections and tags;
- local search;
- annotation export;
- Focus Mode;
- polished desktop/mobile adaptive UI;
- beta PDF Flow Mode for compatible digital PDFs;
- no accounts and no cloud dependency.

# Work ordering rule

When choosing between a flashy new feature and fixing annotation correctness, reader latency, selection quality, or crash recovery, fix the core behavior first.

Kola earns trust by never losing the reader's place or annotations.