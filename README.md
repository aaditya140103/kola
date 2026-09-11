# Kola

Kola is a planned **local-first, cross-platform universal reading and annotation application** for ebooks, PDFs, Word documents, presentations, spreadsheets, comics, and other readable document formats.

The goal is to create a fast, private reader that works across Linux, Windows, macOS, Android, and iOS from one Flutter codebase while still feeling native to each platform.

## Core principles

- Local-first and fully usable offline
- No mandatory account or Kola-hosted cloud
- Optional Bring Your Own Cloud sync across devices
- Universal Flow Mode backed by a source-mapped document graph
- One consistent annotation model across formats
- Broad ebook and office-document support
- Separate position progress and actual reading coverage
- Private reading analytics, active-time tracking, and Reading List / Next Up planning
- Deep reader theme/background customization
- Adaptive-native UI rather than one pixel-identical interface everywhere
- Evidence-based UI/UX: attractive, measurable, accessible, and validated
- User-owned data, sync targets, and exportable annotations
- Reader correctness and performance before decorative complexity
- **No AI assistant layer and no dedicated study-system layer**

## Product wedge

Kola should not compete by having the longest feature list. The product story is:

> **Read almost anything beautifully. Annotate it deeply. Keep your data. Understand your reading life. Continue anywhere without lock-in.**

The strategic combination is:

```text
Beautiful universal reader
+ source-linked Flow Mode
+ best-in-class annotations
+ local-first / BYOC ownership
+ universal local search
+ Reading Intelligence
+ migration and interoperability
+ excellent reader utilities
```

Kola is intentionally **not** becoming an AI chat app, flashcard app, mind-map tool, spaced-repetition system, or knowledge-graph application. Those directions are out of scope unless the product decision is explicitly changed later.

## Architecture direction

- Flutter + Dart application/UI layer
- SQLite + Drift for durable local state
- adapter-based document engine
- Kola Document Graph (KDG) as the normalized semantic representation
- PDFium through a Flutter PDF adapter for PDF fidelity rendering
- local parsers/converters for ebook and office families
- SQLite full-text search
- local Reading Intelligence services over progress/coverage/session data
- isolates/background workers for parsing/indexing
- optional `SyncBackend` adapters for user-owned cloud/storage
- optional Rust/native engines only where broad format support or profiling justifies them

## Specifications

- [Product specification](docs/APP.md)
- [Focused feature strategy](docs/FEATURE_STRATEGY.md)
- [Technical architecture](docs/ARCHITECTURE.md)
- [Adaptive Native Design System](docs/DESIGN_SYSTEM.md)
- [UI/UX specification](docs/UX_SPEC.md)
- [Evidence-based UX research](docs/UX_RESEARCH.md)
- [Scientific UX validation protocol](docs/UX_VALIDATION.md)
- [Competing visual design directions](docs/VISUAL_DIRECTIONS.md)
- [Reading intelligence, analytics, goals, and Reading List](docs/READING_ANALYTICS.md)
- [Universal format strategy](docs/UNIVERSAL_FORMATS.md)
- [Bring Your Own Cloud sync](docs/SYNC.md)
- [Project architecture graphs](docs/PROJECT_GRAPH.md)
- [Decision ledger](docs/DECISIONS.md)
- [Live project state](docs/PROJECT_STATE.md)
- [Implementation roadmap](docs/ROADMAP.md)
- [Research notes](docs/RESEARCH.md)

## Signature ideas

### Universal Flow Mode

A semantic reading mode for supported documents that preserves source mapping. PDFs, ebooks, Word documents, presentations, spreadsheets, and scanned/OCR material can all project into the same reading model at different confidence levels.

### Fidelity View

The closest practical representation of the original source: PDF pages, slides, spreadsheet sheets, document layout, comic pages, and other native structures.

### Best-in-class annotations

Highlights, notes, ink, area annotations, semantic labels, source-linked anchors, exact source jumps, search/filtering, and excellent mouse/keyboard/touch/stylus workflows all operate through one annotation model.

### Reading Progress + Coverage

Kola distinguishes **where you are** from **how much you actually read**, so jumping to the end does not falsely mark a document complete.

### Reading Intelligence

Kola can answer useful private questions such as:

- how long did I actually read today/this week?
- how much time have I spent on this book?
- how many sessions have I spent with it?
- what have I completed this month/year?
- what is on my Want to Read / Next Up list?
- which collections receive most of my reading time?
- how much trusted reading time is estimated to remain?

Reading time is based on meaningful activity rather than simply counting how long a document stays open. Goals and streaks are optional and deliberately non-punitive.

### Bring Your Own Cloud

Kola remains fully local by default, but users may connect storage they control—such as a local sync folder, WebDAV, Google Drive, OneDrive, Dropbox, or S3-compatible storage—to synchronize state and optionally documents between devices.

Kola never synchronizes the live SQLite database file. It exchanges versioned portable records through a conflict-aware sync layer, and document upload is separately opt-in.

### Focus Mode

A distraction-free reader surface with nearly all chrome hidden.

### Peek

Preview footnotes, citations, links, figures, tables, slides, and annotation links without losing reading position.

### Reading Lens

An optional reading guide that isolates a few lines or a paragraph for dense content and accessibility.

### Parallel Read

View two documents or two representations side by side for comparison, translation, revisions, or reference work.

## Cross-platform design rule

Kola uses **consistent semantics with native presentation**.

The product model, wording, annotation behavior, Flow Mode, Reading List, Insights, reading concepts, and sync concepts remain consistent. Navigation, menus, title bars, sheets, scroll behavior, density, keyboard integration, selection behavior, and window chrome adapt to the operating system and available window size.

The objective is not for screenshots to look identical. The objective is for Kola to feel like the same excellent reader intentionally designed for each platform.

## UI/UX research rule

Kola's interface is treated as a measurable product system, not decoration.

The visual thesis is:

> **Calm reading surfaces + familiar structure + high craftsmanship + selective expressive interactions + native platform behavior.**

Meaningful UI decisions should be grounded in accessibility/standards, human-factors evidence, native platform convention, measured Kola user results, or an explicit design experiment. Important designs should be tested using both behavioral metrics and subjective UX/aesthetic measures rather than preference alone.

See `docs/UX_RESEARCH.md` and `docs/UX_VALIDATION.md`.

## Current visual design hypotheses

Kola is intentionally testing multiple directions before locking the final visual system:

- **Luminous Paper** — premium, calm, restrained translucent chrome around a paper-like document surface;
- **Editorial Scholar** — typography/grid-led, information-rich, research-friendly;
- **Soft Expressive** — younger, colorful, personal, tactile and motion-forward;
- **Kola Core candidate** — Luminous Paper structure + Editorial discipline + Soft Expressive interaction feedback.

The full comparison, token roles, prototype requirements, and evaluation criteria live in `docs/VISUAL_DIRECTIONS.md`.

## For coding agents

Start with [`AGENTS.md`](AGENTS.md), then read `docs/PROJECT_STATE.md` and `docs/PROJECT_GRAPH.md`. Load only the detailed specification relevant to the task.

For feature-scope questions, use `docs/FEATURE_STRATEGY.md` instead of independently expanding the roadmap.

Every patch must update `docs/PROJECT_STATE.md`; architecture/data-flow changes must update `docs/PROJECT_GRAPH.md`; durable decisions must update `docs/DECISIONS.md`.

## Status

**Architecture, focused feature strategy, format strategy, adaptive UX, evidence-based UX methodology, visual-direction exploration, Reading Intelligence, and BYOC sync specification phase.**

The next engineering milestone is to initialize the Flutter application and prototype the design-system primitives plus Library/Reader shells before locking the final default appearance.