# Kola — Focused Feature Strategy

Research snapshot: September 2026.

This file defines the committed product direction. Kola should be an excellent universal reader, not a collection of unrelated AI, study, social, or productivity systems.

## 1. Product position

> **Kola is a beautiful, private, universal reading application that lets people read almost any document, annotate it precisely, track their reading, and continue across devices without surrendering ownership of their data.**

The product is intentionally focused on the reading experience itself.

---

# 2. S-tier — defining Kola features

## S1. Universal document support

Kola should read major practical, non-DRM document families through one adapter architecture.

Priority families include:

- PDF / DjVu / fixed-layout documents;
- EPUB and major ebook containers;
- TXT / Markdown / HTML;
- DOCX and word-processing formats;
- PPT/PPTX and presentations;
- XLS/XLSX and spreadsheets;
- CBZ/CBR and visual publications;
- images/scanned documents with optional local OCR;
- additional maintainable non-DRM formats over time.

## S2. Universal source-linked Flow Mode

Kola's strongest technical differentiator.

Requirements:

- source mapping back to the original document;
- annotation compatibility between Flow and Fidelity views;
- reading-position continuity between views;
- safe preservation of figures, tables, equations, slide regions, spreadsheet regions, and other complex structures;
- honest Flow quality/confidence where reconstruction is approximate;
- reader-controlled typography, width, spacing, themes, and backgrounds.

Flow Mode must never become an unrelated converted copy.

## S3. Best-in-class annotation

Required capabilities:

- text highlighting;
- underline and strikeout;
- text and margin notes;
- bookmarks;
- cross-page text selection/highlighting where technically possible;
- image/diagram/area annotation;
- freehand ink;
- shapes/arrows/text boxes where appropriate;
- semantic highlight labels;
- annotation filtering and search;
- exact jump back to source;
- undo/redo;
- mouse, keyboard, touch, and stylus interaction paths;
- hybrid source anchors rather than screen-coordinate-only storage.

## S4. Premium adaptive-native UI/UX

Kola's appearance is part of the product.

Requirements:

- attractive modern visual identity;
- calm long-form reading surfaces;
- evidence-based hierarchy/readability;
- platform-native presentation and behavior;
- compact, medium, and expanded adaptive layouts;
- excellent desktop, phone, tablet, foldable, mouse, keyboard, touch, and stylus behavior;
- application themes;
- reader themes;
- ambient backgrounds;
- polished micro-interactions and motion where they add meaning;
- accessibility, reduced motion, high contrast, large text, and screen-reader support.

Reference: `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.

## S5. Local-first ownership + BYOC

Kola must remain completely usable without an account or Kola-owned cloud.

Core principles:

- local reading works with zero network requests;
- annotations, progress, reading history, library state, and settings are stored locally;
- users can connect their own cloud/storage through `SyncBackend` adapters;
- never synchronize the live SQLite file;
- state-only, selected-document, and full-library sync scopes;
- conflict-aware merge;
- optional client-side encrypted sync vaults;
- sync/network failures never block reading.

Reference: `SYNC.md`.

## S6. Universal local search

Search targets:

- titles/authors/metadata;
- document text;
- OCR text;
- annotations;
- notes;
- presentation text/speaker notes;
- spreadsheet cell text;
- tags/collections.

Every result must resolve back to a useful document location.

## S7. Reading Intelligence + Reading List

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
- optional goals and gentle streaks.

Reference: `READING_ANALYTICS.md`.

## S8. Interoperability, migration, and export

Important directions:

- folder libraries;
- Calibre;
- OPDS;
- KOReader where feasible;
- reading-list CSV imports;
- highlight/note imports from open/exportable formats;
- Markdown/JSON/CSV export;
- annotated PDF export where supported;
- portable Kola backup;
- user-controlled document/annotation export.

Interoperability is acquisition infrastructure, not edge-case polish.

## S9. Read Aloud / TTS

Capabilities:

- local/platform voices first;
- synchronized sentence/paragraph highlighting;
- speed/voice controls;
- background playback where permitted;
- sleep timer;
- visual and spoken reading positions converge on the same source model;
- accessibility-first implementation.

## S10. Selection tools

High-frequency selection actions should include:

- dictionary/definition;
- reference lookup where configured;
- translation;
- copy/share;
- annotation actions.

Network-backed lookup/translation must remain optional.

## S11. Parallel Read / Compare

Two sources can be viewed together for tasks such as:

- original + translation;
- two versions of a document;
- two research papers;
- presentation + reference;
- textbook + another source.

Support independent and synchronized navigation where meaningful.

---

# 3. Explicitly out of scope

The following are **not committed Kola product features** and should not be added unless the product decision is explicitly revisited:

- AI assistants;
- BYO AI;
- local LLM integration;
- document chat/Q&A;
- AI summaries/explanations;
- semantic AI search;
- flashcard systems;
- spaced-repetition/SRS schedulers;
- persistent knowledge-card systems;
- backlinks/knowledge graphs;
- graph views;
- mind maps/concept boards;
- Recall Mode;
- dedicated study-sheet systems;
- quiz-generation systems;
- plugin/extension SDK as a committed product feature;
- built-in public social network/book clubs;
- badges/coins/XP gamification;
- proprietary ebook store;
- mandatory Kola account.

The product should stay centered on **reading, annotation, navigation, personalization, analytics, ownership, and continuity**.

---

# 4. Product priority order

## Phase 1 — core reader

1. adaptive premium visual shell;
2. local library/persistence;
3. PDF + EPUB excellence;
4. universal adapter boundaries;
5. annotation correctness;
6. Flow Mode foundation;
7. universal local search;
8. themes/backgrounds;
9. progress + coverage;
10. Reading Intelligence foundations;
11. backup/export.

## Phase 2 — complete universal reader

Add/mature:

- broader document formats;
- BYOC state sync;
- migration/import/export;
- Reading List and analytics;
- TTS;
- dictionary/translation;
- Parallel Read;
- OPDS/Calibre/KOReader interoperability where feasible.

## Phase 3 — refinement and depth

Focus on:

- annotation ergonomics;
- large-library performance;
- long-session reading comfort;
- stronger Flow reconstruction;
- better Office/presentation/spreadsheet fidelity;
- sync resilience;
- accessibility;
- platform-specific polish;
- import/export reliability;
- analytics quality;
- advanced reader customization.

No AI or study-system layer is planned.

---

# 5. Feature proposal rule

Before adding a feature, ask:

1. Does it improve reading, annotation, navigation, ownership, continuity, accessibility, or useful reading insight?
2. Does it strengthen one of the S-tier capabilities?
3. Can it remain local-first or explicitly optional-network?
4. Can it reuse existing Kola domain models?
5. Is there credible user value or evidence?
6. Will users notice the benefit enough to justify its complexity?
7. What higher-priority work would it delay?

If the feature mainly turns Kola into an AI, study, social, or generic productivity app, the default decision is **do not add it**.

---

# 6. Final product identity

```text
Beautiful universal reader
+ universal source-linked Flow Mode
+ best-in-class annotations
+ local-first ownership + BYOC
+ universal local search
+ Reading Intelligence
+ migration/interoperability
+ Read Aloud / translation / compare
```

Kola should become deeper, not broader for its own sake.
