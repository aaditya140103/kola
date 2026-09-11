# Kola — Agent Instructions

**Scope:** this file applies to the entire repository tree.

## Start here

Before changing anything, read only:

1. `AGENTS.md`
2. `docs/PROJECT_STATE.md`
3. `docs/PROJECT_GRAPH.md`
4. The one detailed spec relevant to the task

Do not load every document unless necessary.

## Product

Kola is a **local-first, cross-platform universal document reader and annotation workspace** built with one Flutter/Dart codebase for Linux, Windows, macOS, Android, iOS, tablets, and foldables.

It should read mainstream ebooks, PDFs, office documents, presentations, spreadsheets, comics, text/markup, and image-based documents through format adapters. It provides Fidelity View + universal source-linked Flow Mode, highlights, notes, ink, search, bookmarks, progress/coverage tracking, themes/backgrounds, and local export. Core reading must work without accounts, cloud services, telemetry, or internet access.

## Non-negotiable invariants

1. **Local-first:** local reading makes zero network requests.
2. **One codebase:** Flutter/Dart owns app + UI across targets.
3. **Universal model:** format parsers feed Kola-owned normalized document structures.
4. **Two views, one source:** Fidelity View and Flow Mode share document identity.
5. **Source-linked annotations:** never anchor only to screen coordinates.
6. **Adaptive-native UX:** same semantics; platform-native presentation/interaction.
7. **User-owned data:** metadata, progress, annotations, indexes, and exports remain local.
8. **Graceful degradation:** reflow/index/parser failures must not block readable source content.
9. **Performance first:** reading/selection/annotation correctness beats decoration.
10. **No DRM bypass.**

## Core stack

- Flutter + Dart
- Riverpod
- go_router
- SQLite + Drift
- SQLite FTS5 where available
- PDFium behind an adapter; initial Flutter candidate `pdfrx`
- Dart isolates/background workers
- Rust only later if profiling/capability requires it

## Core architecture

```text
Adaptive platform shell
  -> Flutter app + Kola design system
  -> application/use cases
  -> Kola document domain
  -> DocumentAdapter registry
  -> format engines/parsers
  -> NormalizedDocument + SourceMap
  -> Fidelity View | Flow Mode | Search | Annotation
  -> SQLite/Drift + local files + disposable caches
```

## Universal format contract

Each format adapter should expose as much as it can of:

- metadata
- structure / TOC
- fidelity rendering
- content/text extraction
- source mapping
- search chunks
- normalized Flow representation
- annotation resolution
- progress units
- export capability

Target families include PDF/DjVu, EPUB/ebook containers, TXT/Markdown/HTML, DOCX/word-processing, PPT/PPTX/presentations, XLS/XLSX/spreadsheets, CBZ/CBR, image folders/scans, and other practical non-DRM formats.

## Flow Mode rule

Flow Mode is a projection of `NormalizedDocument`, not a PDF-only feature.

```text
source -> adapter -> normalized blocks + source map -> Flow renderer
                                             -> source-linked annotations
```

Complex tables, figures, slides, spreadsheet regions, or objects that cannot safely reflow stay as source-preserving visual blocks.

## Annotation rule

A text annotation anchor should combine available selectors:

- structural/source locator
- exact quote
- prefix/suffix context
- logical offsets
- source geometry/quads

Resolution order: source locator -> verify quote -> offsets -> quote/context -> unresolved. Never silently attach to wrong content.

## Reading progress

Keep these separate:

- **Position progress:** where the reader currently is.
- **Reading coverage:** how much content was actually traversed/read.

Both persist locally and are format-independent at the domain level.

## Theme rule

Application chrome theme and document reading theme are separate. A dark shell may show a warm/paper reader surface. Support system/light/dark app chrome and reader themes/background customization.

## UX rule

**Consistent semantics, native presentation.**

Keep Library, Search, Collections, Continue Reading, Fidelity View, Flow Mode, Focus Mode, annotations, progress, and themes conceptually stable.

Adapt navigation, title/window chrome, dialogs, sheets, context menus, back behavior, scroll physics, scrollbars, selection UI, haptics, hover/right-click, keyboard accelerators, safe areas, density, and touch targets by platform/window/input.

Use available window size + input capability, not simplistic `isPhone`/`isTablet` logic.

## Stable domain vocabulary

Prefer app-owned models/interfaces such as:

`Document`, `DocumentSource`, `DocumentMetadata`, `DocumentAdapter`, `DocumentHandle`, `NormalizedDocument`, `DocumentSection`, `DocumentBlock`, `SourceMap`, `DocumentLocation`, `Annotation`, `AnnotationAnchor`, `ReadingState`, `ReadingSession`, `ReadingCoverage`, `ReaderTheme`, `Collection`, `SearchResult`, `ExportRequest`.

Do not leak third-party package types through feature/domain layers.

## Detailed specs — read only when relevant

- Product: `docs/APP.md`
- Architecture/data: `docs/ARCHITECTURE.md`
- Adaptive native design: `docs/DESIGN_SYSTEM.md`
- UX interactions: `docs/UX_SPEC.md`
- Formats: `docs/UNIVERSAL_FORMATS.md`
- Build order: `docs/ROADMAP.md`
- Research: `docs/RESEARCH.md`
- Settled decisions: `docs/DECISIONS.md`

## Mandatory patch protocol

**Every agent, on every code/documentation patch, must update `docs/PROJECT_STATE.md` before finishing.**

The state update must be short and contain:

- what changed
- current milestone/status
- important files touched
- any new blocker/risk
- next recommended action

Additionally:

- If architecture or data flow changed -> update `docs/PROJECT_GRAPH.md`.
- If a durable product/technical choice changed -> update `docs/DECISIONS.md`.
- If requirements changed -> update the relevant detailed spec.
- Never duplicate long context into agent-specific instruction files.

A patch is incomplete until the required context files are synchronized.

## Change discipline

- Preserve source compatibility and user data where practical.
- Keep caches disposable; user-generated data is never a cache.
- Background parsing/indexing must not block the reader UI.
- Avoid premature package/microservice/module splitting.
- Do not add cloud/account/network dependencies to core reading.
- Do not replace settled architecture without documenting the decision.
- Prefer small coherent changes and tests over broad speculative rewrites.

## Definition of done for an agent patch

1. Requested change implemented.
2. Relevant tests/checks added or updated where applicable.
3. No invariant above violated.
4. `docs/PROJECT_STATE.md` updated.
5. Graph/decision/spec files updated if the patch affected them.
