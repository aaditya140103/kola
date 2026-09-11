# Kola

Kola is a planned **local-first, cross-platform universal reading and annotation application** for ebooks, PDFs, Word documents, presentations, spreadsheets, comics, and other readable document formats.

The goal is to create a fast, private reader that works across Linux, Windows, macOS, Android, and iOS from one Flutter codebase while still feeling native to each platform.

## Core principles

- Local-first and fully usable offline
- No mandatory account or cloud backend
- Universal Flow Mode backed by a source-mapped document graph
- One consistent annotation model across formats
- Broad ebook and office-document support
- Separate position progress and actual reading coverage
- Deep reader theme/background customization
- Adaptive-native UI rather than one pixel-identical interface everywhere
- User-owned data and exportable annotations
- Reader correctness and performance before decorative complexity

## Architecture direction

- Flutter + Dart application/UI layer
- SQLite + Drift for durable local state
- adapter-based document engine
- Kola Document Graph (KDG) as the normalized semantic representation
- PDFium through a Flutter PDF adapter for PDF fidelity rendering
- local parsers/converters for ebook and office families
- SQLite full-text search
- isolates/background workers for parsing/indexing
- optional Rust/native engines only where broad format support or profiling justifies them

## Specifications

- [Product specification](docs/APP.md)
- [Technical architecture](docs/ARCHITECTURE.md)
- [Adaptive Native Design System](docs/DESIGN_SYSTEM.md)
- [UI/UX specification](docs/UX_SPEC.md)
- [Universal format strategy](docs/UNIVERSAL_FORMATS.md)
- [Implementation roadmap](docs/ROADMAP.md)
- [Research notes](docs/RESEARCH.md)

## Signature ideas

### Universal Flow Mode

A semantic reading mode for supported documents that preserves source mapping. PDFs, ebooks, Word documents, presentations, spreadsheets, and scanned/OCR material can all project into the same reading model at different confidence levels.

### Fidelity View

The closest practical representation of the original source: PDF pages, slides, spreadsheet sheets, document layout, comic pages, and other native structures.

### Reading Progress + Coverage

Kola distinguishes **where you are** from **how much you actually read**, so jumping to the end does not falsely mark a document complete.

### Focus Mode

A distraction-free reader surface with nearly all chrome hidden.

### Peek

Preview footnotes, citations, links, figures, tables, slides, and annotation links without losing the current reading position.

### Reading Lens

An optional reading guide that isolates a few lines or a paragraph for dense material.

### Annotation Rail

Small edge markers reveal where annotations exist without requiring a permanent sidebar.

## Cross-platform design rule

Kola uses **consistent semantics with native presentation**.

The product model, wording, annotation behavior, Flow Mode, and reading concepts remain consistent. Navigation, menus, title bars, sheets, scroll behavior, density, keyboard integration, selection behavior, and window chrome adapt to the operating system and available window size.

The objective is not for screenshots to look identical. The objective is for Kola to feel like the same excellent reader intentionally designed for each platform.

## Status

**Architecture, format strategy, and UX/design-system specification phase.**

The next engineering milestone is to initialize the Flutter application, adaptive design primitives, local database, routing/state architecture, and CI, followed by the first document adapters and reader surfaces.