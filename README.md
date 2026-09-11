# Kola

Kola is a planned **local-first, cross-platform reading and annotation application** for PDF, EPUB and other document/book formats.

The goal is to create a fast, private reader that works across Linux, Windows, macOS, Android and iOS from one Flutter codebase, with first-class highlighting, notes, ink, local search, adaptive reading modes and a source-linked PDF Flow Mode.

## Core principles

- Local-first and fully usable offline
- No mandatory account or cloud backend
- One consistent annotation system across formats
- PDF and EPUB as first-class formats
- Adaptive desktop, tablet and mobile UX
- User-owned data and exportable annotations
- Reader performance and annotation correctness before feature breadth

## Planned stack

- Flutter + Dart
- SQLite + Drift
- PDFium through a Flutter PDF adapter (initial candidate: `pdfrx`)
- EPUB parser behind an app-owned document adapter
- SQLite full-text search
- Dart isolates for parsing/indexing/background work

Rust is deliberately not part of the v1 critical path. It can be introduced later for CPU-heavy document analysis, OCR or codecs if profiling demonstrates a need.

## Specifications

- [Product specification](docs/APP.md)
- [Technical architecture](docs/ARCHITECTURE.md)
- [UI/UX specification](docs/UX_SPEC.md)
- [Implementation roadmap](docs/ROADMAP.md)
- [Research notes](docs/RESEARCH.md)

## Signature ideas

### Flow Mode

A reflowed reading mode for compatible PDFs that preserves source mapping, so highlights and notes remain tied to the original PDF location.

### Focus Mode

A distraction-free reader surface with nearly all chrome hidden.

### Peek

Preview footnotes, citations, internal links, figures and annotation links without losing the current reading position.

### Reading Lens

An optional movable reading guide that isolates a few lines or a paragraph for dense material.

### Annotation Rail

Small edge markers reveal where annotations exist without requiring a permanent sidebar.

## Status

**Architecture and product specification phase.**

The next engineering milestone is Phase 0 from `docs/ROADMAP.md`: initialize the Flutter application, design system, local database, routing, state management and CI before starting the PDF reader.
