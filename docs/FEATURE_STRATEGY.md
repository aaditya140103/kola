# Kola — Focused Feature Strategy

Research snapshot: September 2026.

This file defines the **committed product scope** for Kola.

Kola is a reader. It is not an AI assistant, study suite, knowledge-management system, social network, or productivity super-app.

The product should become deeper and more polished around reading itself rather than broader for its own sake.

## 1. Product position

> **Kola is a beautiful, private, universal reading application for books and documents: read almost anything, annotate it precisely, search it locally, understand your reading habits, and continue across devices while keeping ownership of your files and data.**

The committed product is built around one reading stack:

```text
Universal document support
+ Fidelity View
+ source-linked Flow Mode
+ best-in-class annotation
+ premium adaptive-native UI
+ local-first ownership + optional BYOC
+ universal local search
+ Reading Intelligence
+ import/export/interoperability
+ read-aloud and reader utilities
```

## 2. S-tier — defining Kola features

These features define Kola and outrank speculative expansion.

### S1. Universal document support

Kola should read major practical, non-DRM document families through one adapter architecture.

Priority families:

- PDF / DjVu / fixed-layout documents;
- EPUB and major ebook containers;
- TXT / Markdown / HTML;
- DOCX / ODT / RTF and other maintainable word-processing formats;
- PPT/PPTX / ODP presentations;
- XLS/XLSX / ODS / CSV spreadsheets;
- CBZ/CBR and visual publications;
- images and scanned documents with local OCR where feasible;
- additional maintainable non-DRM formats over time.

The user should not need another app just because the readable file format changed.

### S2. Universal source-linked Flow Mode

This is Kola's strongest technical differentiator.

Requirements:

- every supported format attempts to project into the Kola Document Graph;
- source mapping back to the original document;
- annotation compatibility between Flow and Fidelity views;
- reading-position continuity between views;
- safe preservation of figures, tables, equations, slide regions, spreadsheet regions, and other complex structures;
- honest quality/confidence states when reconstruction is approximate;
- typography, width, spacing, themes, and backgrounds controlled by the reader.

Flow Mode must never become an unrelated converted copy.

### S3. Best-in-class annotation

Annotation quality is a trust feature.

Required capabilities:

- highlight;
- underline;
- strikeout;
- text notes and margin notes;
- bookmarks;
- cross-page selection/highlighting where technically possible;
- image/diagram/area annotation;
- freehand ink;
- shapes/arrows/text boxes where appropriate;
- semantic highlight labels;
- filtering and search;
- exact jump back to source;
- undo/redo;
- mouse, keyboard, touch, and stylus workflows;
- hybrid source anchors rather than screen-coordinate-only storage.

### S4. Premium adaptive-native UI/UX

Kola's appearance is part of the product.

Requirements:

- attractive modern visual identity;
- calm long-form reading surfaces;
- evidence-based hierarchy and readability;
- native platform presentation and behavior;
- compact, medium, expanded, large, and extra-large adaptive layouts;
- excellent desktop, phone, tablet, foldable, mouse, keyboard, touch, and stylus behavior;
- application themes;
- reader themes;
- ambient backgrounds;
- high-quality micro-interactions and motion where useful;
- accessibility, reduced motion, high contrast, large text, and screen-reader support.

Reference: `UX_RESEARCH.md`, `UX_VALIDATION.md`, `VISUAL_DIRECTIONS.md`.

### S5. Local-first ownership + Bring Your Own Cloud

Kola must remain fully usable without an account or Kola-owned cloud.

Core rules:

- local reading makes zero network requests;
- annotations, progress, reading history, library state, and settings are stored locally;
- users may connect storage they control through `SyncBackend` adapters;
- never synchronize the live SQLite database file;
- support state-only, selected-document, and full-library sync scopes;
- conflict-aware merge;
- optional client-side encrypted sync vaults;
- sync/network failures never block reading.

Reference: `SYNC.md`.

### S6. Universal local search

Search should cover:

- title/author/metadata;
- document text;
- OCR text;
- annotations and notes;
- presentation text and speaker notes;
- spreadsheet cell text;
- tags and collections.

Every result must resolve back to a useful source location.

### S7. Reading Intelligence + Reading List

Kola should help users understand their reading without turning it into a compulsive scoreboard.

Capabilities:

- trusted active reading time;
- reading sessions;
- position progress;
- actual reading coverage;
- per-document insights;
- daily/weekly/monthly/yearly analytics;
- first/last read date;
- completion history;
- estimated time remaining when enough trusted data exists;
- Want to Read;
- Next Up;
- Reading;
- Paused;
- Completed;
- optional Abandoned/DNF;
- optional gentle goals/streaks.

Reference: `READING_ANALYTICS.md`.

### S8. Interoperability, migration, backup, and export

Switching to Kola should not require rebuilding a reading life from zero.

Important directions:

- folder libraries;
- Calibre;
- OPDS;
- KOReader where feasible;
- reading-list CSV imports;
- highlight/note imports from open/exportable formats;
- Markdown / JSON / CSV export;
- annotated PDF export where supported;
- portable Kola backup;
- user-controlled document and annotation export.

### S9. Read Aloud / TTS

Capabilities:

- local/platform voices first;
- synchronized sentence/paragraph highlighting;
- speed and voice controls;
- background playback where permitted;
- sleep timer;
- visual and spoken positions resolve to the same source model;
- accessibility-first implementation.

### S10. Reader selection tools

High-frequency actions may include:

- dictionary/definition;
- optional reference lookup;
- optional translation;
- copy/share;
- annotation actions.

Any network-backed lookup remains optional and explicit.

### S11. Parallel Read / Compare

Two sources can be viewed together for:

- original + translation;
- two versions of a document;
- two papers/books/documents;
- presentation + reference;
- any reading task where side-by-side comparison is useful.

Support independent or synchronized navigation where meaningful.

### S12. Advanced reading ergonomics

Kola-specific reading aids may include:

- Focus Mode;
- Reading Lens;
- Peek for footnotes/references/figures;
- crop margins;
- document tabs on desktop;
- history back/forward;
- customizable shortcuts;
- fullscreen reading;
- page/column/layout preferences;
- touch/stylus ergonomics.

These remain reading features, not study-system features.

## 3. Explicitly out of scope

The following are **not Kola product features** unless this decision is explicitly revisited:

### AI / assistant systems

- AI chat;
- BYO AI;
- cloud AI;
- local LLM features;
- document Q&A using LLMs;
- AI summaries;
- AI explanations;
- AI-generated quizzes;
- semantic/embedding search that requires an AI model;
- AI recommendations;
- AI OCR correction assistants.

### Dedicated study systems

- flashcards;
- spaced repetition / SRS;
- study decks;
- Recall Mode;
- mind maps / concept boards;
- backlinks / knowledge graph;
- persistent knowledge cards;
- study sheets;
- quiz systems;
- learning streaks unrelated to ordinary reading goals.

### Other excluded product directions

- built-in public social network;
- book-club infrastructure as a core feature;
- proprietary ebook store;
- badges/coins/XP systems;
- mandatory Kola account;
- mandatory Kola-hosted cloud;
- plugin SDK before there is a separate explicit product decision.

Ordinary annotations, notes, collections, search, reading analytics, and exports remain part of the reader and should not be reclassified as study tooling.

## 4. Product priority order

### Phase A — Trust the reader

Prioritize:

1. adaptive premium visual shell;
2. local library and persistence;
3. PDF + EPUB excellence;
4. universal adapter boundaries;
5. annotation correctness;
6. Flow Mode foundation;
7. local search;
8. themes/backgrounds;
9. progress + coverage;
10. Reading Intelligence foundations;
11. backup/export.

### Phase B — Universal reader breadth

Add/mature:

- broader ebook/document formats;
- Office-family reading;
- presentations and spreadsheets;
- local OCR;
- Flow Mode across those formats;
- ink/stylus;
- advanced reader ergonomics.

### Phase C — Continuity and interoperability

Add/mature:

- BYOC state sync;
- migration/import/export;
- Reading List and analytics;
- TTS;
- dictionary/translation;
- Parallel Read;
- OPDS/Calibre/KOReader interoperability where feasible;
- robust backup/restore.

### Phase D — polish and reliability

Invest in:

- startup/open latency;
- large-library performance;
- huge-document performance;
- rendering smoothness;
- crash recovery;
- annotation durability;
- accessibility;
- platform-native polish;
- long-session comfort;
- battery/memory use;
- test corpus expansion.

There is no planned AI or study-system phase.

## 5. Feature proposal rule

Before adding a feature, ask:

1. Does it directly improve reading, annotation, navigation, search, personalization, continuity, ownership, or reading insight?
2. Does it strengthen one of the S-tier features above?
3. Can it remain local-first or explicitly optional-network?
4. Can it reuse the existing Kola document/annotation/progress architecture?
5. Is there credible user value?
6. Will users notice the benefit enough to justify its complexity?
7. What higher-priority reader work would it delay?
8. Is it AI or a dedicated study system? If yes, **do not add it** under the current scope.

## 6. Final product identity

```text
Beautiful universal reader
+ universal source-linked Flow Mode
+ best-in-class annotations
+ local-first ownership + BYOC
+ universal local search
+ Reading Intelligence
+ migration/interoperability
+ read-aloud and reader utilities
+ excellent cross-platform ergonomics
```

Kola should be known for being an unusually beautiful, capable, private **reader**.