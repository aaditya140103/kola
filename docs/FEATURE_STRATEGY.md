# Kola — Focused Feature Strategy

Research snapshot: September 2026.

This file defines the **committed product feature direction**. It is intentionally narrower than a general brainstorm.

Kola should not become a collection of unrelated study, social, productivity, and AI tools. It should be an excellent universal reader with a small number of unusually strong capabilities.

## 1. Product position

> **Kola is a beautiful, private, universal reading application that lets people read almost any document, annotate it precisely, understand it with optional BYO AI, track their reading, and continue across devices without surrendering ownership of their data.**

The product has two strategic layers:

1. **S-tier reading core** — the capabilities that define Kola.
2. **Optional BYO AI layer** — intelligence that operates on the reading core without becoming mandatory infrastructure.

Everything else must justify itself against those two layers.

---

# 2. S-tier — defining Kola features

These are the highest-priority product capabilities. They should receive engineering and design attention before speculative expansion.

## S1. Universal document support

Kola should read major practical, non-DRM document families through one adapter architecture.

Priority families include:

- PDF / DjVu / fixed-layout documents;
- EPUB and major ebook containers;
- TXT / Markdown / HTML;
- DOCX / word-processing formats;
- PPT/PPTX and presentations;
- XLS/XLSX and spreadsheets;
- CBZ/CBR and visual publications;
- images/scanned documents with optional local OCR;
- additional maintainable non-DRM formats over time.

The user should not need a separate app just because the readable file format changed.

## S2. Universal source-linked Flow Mode

This is Kola's strongest technical differentiator.

Every supported document attempts to project into the Kola Document Graph and therefore into Flow Mode.

Requirements:

- source mapping back to the original document;
- annotation compatibility between Flow and Fidelity views;
- reading-position continuity between views;
- safe preservation of figures, tables, equations, slide regions, spreadsheet regions, and other complex structures;
- Flow quality/confidence exposed honestly where reconstruction is approximate;
- typography, width, spacing, themes, and backgrounds controlled by the reader.

Flow Mode must never become an unrelated converted copy.

## S3. Best-in-class annotation

Annotation quality is a trust feature.

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
- high-quality micro-interactions and motion where they add meaning;
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

Search must work across the entire local reading library.

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

Classic local full-text search is mandatory and remains available regardless of AI configuration.

## S7. Reading Intelligence + Reading List

Kola should understand the user's reading activity without turning reading into a compulsive scoreboard.

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

Switching to Kola should not require rebuilding a reading life from zero.

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

Reading should be able to continue away from the screen.

Capabilities:

- local/platform voices first;
- synchronized sentence/paragraph highlighting;
- speed/voice controls;
- background playback where permitted;
- sleep timer;
- visual and spoken reading positions converge on the same source model;
- accessibility-first implementation.

## S10. Selection tools: dictionary, lookup, translation

High-frequency selection actions should include:

- dictionary/definition;
- reference lookup where configured;
- translation;
- copy/share;
- annotation actions;
- optional AI actions when BYO AI is configured.

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

# 3. Optional BYO AI layer

AI is a major Kola feature layer, but **Kola must never require Kola-hosted AI**.

Users bring the intelligence provider they want, or use a compatible local/on-device model.

Detailed design belongs in `AI.md`.

## AI backend direction

Potential backends:

- operating-system/on-device model APIs;
- local model runtime;
- Ollama-compatible local endpoint;
- user-configured OpenAI-compatible endpoint;
- user-supplied API key/provider adapters where explicitly supported later.

AI must be disabled cleanly when no provider is configured.

## AI reading actions

### Explain

- explain selected passage;
- explain terminology;
- explain equation/concept where extracted context permits it;
- simplify difficult prose;
- adjust explanation depth.

### Summarize

- summarize selection;
- current page/slide/section;
- chapter;
- whole document;
- selected documents;
- produce short, medium, or detailed summaries.

### Ask the document

- question answering over the current document;
- Q&A over multiple explicitly selected documents;
- follow-up questions within a reading session;
- answers cite source locations whenever technically possible.

### Compare documents

- summarize similarities/differences;
- compare arguments;
- compare versions/revisions;
- compare definitions or claims;
- identify agreements and contradictions;
- cite both sources.

### Translation and rewriting

- translate selected content;
- translate sections;
- simplify wording;
- rewrite dense text into clearer language;
- preserve the original source next to generated output.

### Structure extraction

- generate document outline suggestions;
- identify headings/sections when source structure is weak;
- produce key-point lists;
- create local glossary of important terms;
- identify people/places/concepts mentioned in the selected scope.

### Reading assistance

- explain highlighted passages;
- answer “what does this refer to?” using nearby context;
- produce a reading brief before entering a long document;
- recap what the user has read so far;
- summarize changes since the user's previous reading position;
- answer questions against the user's explicitly selected local library scope.

### Research assistance

- extract claims and supporting evidence;
- identify cited references present in the document text;
- compare evidence across selected documents;
- find passages relevant to a user question through AI-assisted retrieval;
- create source-grounded synthesis across selected documents.

### Document cleanup assistance

- suggest OCR corrections;
- detect suspicious OCR text;
- propose reading-order corrections for Flow Mode diagnostics;
- suggest metadata/title/author cleanup;
- never silently rewrite the source file.

### Analytics assistance

Using local Reading Intelligence data when the user permits it:

- summarize reading habits;
- answer “what did I spend the most time reading this month?”;
- summarize recently completed books/documents;
- help choose from the user's Next Up queue;
- recommend items already present in the user's own library/list based on explicit criteria.

## AI UX rules

- AI is clearly optional.
- AI output is visually distinct from source content.
- Generated text never becomes an annotation or source edit without explicit user action.
- Source-grounded answers show citations/locations where possible.
- The UI shows the scope used: selection, section, document, or selected documents.
- The user controls whether content may leave the device when a remote provider is used.
- Prefer local/on-device processing when practical.
- Never imply that an AI answer is part of the original document.

---

# 4. Explicitly out of scope

The following are **not committed Kola product features** and should not be added by agents unless the product decision is explicitly revisited:

- flashcard system;
- spaced-repetition/SRS scheduler;
- Highlight → Flashcard workflow;
- persistent knowledge-card system;
- backlinks/knowledge graph;
- graph view;
- mind maps/concept boards;
- Recall Mode;
- dedicated study-sheet system;
- plugin/extension SDK as a committed product feature;
- built-in public social network/book clubs;
- badges/coins/XP gamification;
- proprietary ebook store;
- mandatory Kola account;
- mandatory Kola-hosted AI;
- cloud-only AI.

AI may generate **temporary explanatory or question content**, but this must not silently recreate a persistent flashcard/SRS/mind-map/knowledge-graph subsystem.

---

# 5. Product priority order

## Phase 1 — S-tier reading core

Prioritize:

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

## Phase 2 — complete the universal reader

Add/mature:

- broader document formats;
- BYOC state sync;
- migration/import/export;
- Reading List and analytics;
- TTS;
- dictionary/translation;
- Parallel Read;
- OPDS/Calibre/KOReader interoperability where feasible.

## Phase 3 — BYO AI

After document extraction, source mapping, and search are trustworthy:

- provider abstraction;
- on-device/local backends;
- remote BYO provider support;
- explain/summarize/translate;
- source-grounded document Q&A;
- multi-document compare/synthesis;
- AI-assisted reading and research actions;
- OCR/structure cleanup assistance;
- analytics assistance.

AI should reuse Kola's existing document graph, source map, search, annotation, and privacy architecture rather than creating a parallel content system.

---

# 6. Feature proposal rule

Before adding a feature, ask:

1. Does it strengthen the S-tier reader or BYO AI layer?
2. Does it improve reading, annotation, understanding, continuity, ownership, or useful reading insight?
3. Can it remain local-first or explicitly optional-network?
4. Can it reuse existing Kola domain models?
5. Is there credible user value or evidence?
6. Will users notice the benefit enough to justify its complexity?
7. What higher-priority work would it delay?

If the answer to question 1 is **no**, the default decision is not to add it.

---

# 7. Final product identity

```text
Beautiful universal reader
+ universal source-linked Flow Mode
+ best-in-class annotations
+ local-first ownership + BYOC
+ universal local search
+ Reading Intelligence
+ migration/interoperability
+ Read Aloud / translation / compare
+ optional BYO AI
```

Kola should become deeper, not broader for its own sake.
