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

It should read mainstream ebooks, PDFs, office documents, presentations, spreadsheets, comics, text/markup, and image-based documents through format adapters. It provides Fidelity View + universal source-linked Flow Mode, highlights, notes, ink, search, bookmarks, progress/coverage tracking, themes/backgrounds, local export, and optional **Bring Your Own Cloud (BYOC)** synchronization. Core reading must work without accounts, cloud services, telemetry, or internet access.

## Non-negotiable invariants

1. **Local-first:** local reading makes zero network requests.
2. **Optional sync:** cloud sync is user-configured transport; Kola never requires a Kola-hosted cloud.
3. **One codebase:** Flutter/Dart owns app + UI across targets.
4. **Universal model:** format parsers feed Kola-owned normalized document structures.
5. **Two views, one source:** Fidelity View and Flow Mode share document identity.
6. **Source-linked annotations:** never anchor only to screen coordinates.
7. **Adaptive-native UX:** same semantics; platform-native presentation/interaction.
8. **Evidence-based UX:** meaningful visual/interaction choices need evidence, accessibility, platform convention, or an explicit experiment.
9. **User-owned data:** metadata, progress, annotations, indexes, exports, and sync targets remain user-controlled.
10. **Graceful degradation:** reflow/index/parser/sync failures must not block readable local source content.
11. **Performance first:** reading/selection/annotation correctness beats decoration.
12. **No DRM bypass.**

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
  -> optional Sync Projection -> user-selected SyncBackend
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

## Sync rule

BYOC sync is optional and must never become part of the reader's critical path.

- Never sync the live SQLite database file.
- Project syncable entities into versioned portable records.
- Merge into local SQLite transactionally.
- Provider integrations live behind a `SyncBackend` abstraction.
- Initial backend families: local folder, WebDAV, Google Drive, OneDrive, Dropbox, S3-compatible storage.
- Users choose state-only, selected-document, or full-library sync.
- Client-side encrypted vaults are a planned privacy option.
- Network/sync errors never block local reading or annotation.

Detailed design: `docs/SYNC.md`.

## UX rule

**Consistent semantics, native presentation.**

Keep Library, Search, Collections, Continue Reading, Fidelity View, Flow Mode, Focus Mode, annotations, progress, themes, and Sync conceptually stable.

Adapt navigation, title/window chrome, dialogs, sheets, context menus, back behavior, scroll physics, scrollbars, selection UI, haptics, hover/right-click, keyboard accelerators, safe areas, density, and touch targets by platform/window/input.

Use available window size + input capability, not simplistic `isPhone`/`isTablet` logic.

## Evidence-based UX rule

Kola's appearance is a product feature, but "looks modern" is not a sufficient rationale for a meaningful UI change.

Before implementing or substantially changing a visual/interaction pattern, use the smallest relevant evidence class:

1. accessibility/standards requirement;
2. peer-reviewed human-factors/HCI evidence;
3. host-platform convention;
4. measured Kola user preference/behavior;
5. deliberate experimental/brand choice that does not violate 1–4.

Design direction:

- calm, low-complexity reading surfaces;
- high craftsmanship and alignment;
- familiar information architecture;
- selective expressive motion/color at interaction moments;
- document content visually dominates reader chrome;
- progressive disclosure rather than exposing every tool at once;
- generous touch targets and platform-native interaction behavior;
- reader typography optimized for sustained reading and user customization.

For meaningful UI/UX work, read:

- `docs/UX_RESEARCH.md` for the evidence base;
- `docs/UX_VALIDATION.md` for the testing method;
- `docs/VISUAL_DIRECTIONS.md` for the active competing visual hypotheses;
- then the relevant `DESIGN_SYSTEM.md` / `UX_SPEC.md` section.

Meaningful UX changes should identify their rationale in implementation/PR context as one or more of: `evidence`, `accessibility`, `platform convention`, `measured result`, `experiment`.

### Current visual hypotheses

Do not treat one visual style as final yet. The current comparison set is:

- **Luminous Paper** — calm premium surfaces + restrained translucent chrome;
- **Editorial Scholar** — typography/grid-first, information-rich, research-friendly;
- **Soft Expressive** — younger, colorful, tactile, highly personal;
- **Kola Core candidate** — Luminous Paper structure + Editorial discipline + Soft Expressive interaction feedback.

Until validated, shared UI primitives should be tokenized enough that these directions can be compared without rewriting feature logic.

## Stable domain vocabulary

Prefer app-owned models/interfaces such as:

`Document`, `DocumentSource`, `DocumentMetadata`, `DocumentAdapter`, `DocumentHandle`, `NormalizedDocument`, `DocumentSection`, `DocumentBlock`, `SourceMap`, `DocumentLocation`, `Annotation`, `AnnotationAnchor`, `ReadingState`, `ReadingSession`, `ReadingCoverage`, `ReaderTheme`, `Collection`, `SearchResult`, `ExportRequest`, `SyncVault`, `SyncBackend`, `SyncRecord`.

Do not leak third-party package/provider types through feature/domain layers.

## Detailed specs — read only when relevant

- Product: `docs/APP.md`
- Architecture/data: `docs/ARCHITECTURE.md`
- Adaptive native design: `docs/DESIGN_SYSTEM.md`
- UX interactions: `docs/UX_SPEC.md`
- UX evidence/research: `docs/UX_RESEARCH.md`
- UX scientific validation: `docs/UX_VALIDATION.md`
- Competing visual directions: `docs/VISUAL_DIRECTIONS.md`
- Formats: `docs/UNIVERSAL_FORMATS.md`
- Optional BYOC sync: `docs/SYNC.md`
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
- If a meaningful UX pattern changes -> verify it against `UX_RESEARCH.md`; define/record validation work using `UX_VALIDATION.md` where appropriate.
- If a visual style/token/component choice is being locked -> compare it against `VISUAL_DIRECTIONS.md` and record why the selected direction won.
- Never duplicate long context into agent-specific instruction files.

A patch is incomplete until the required context files are synchronized.

## Change discipline

- Preserve source compatibility and user data where practical.
- Keep caches disposable; user-generated data is never a cache.
- Background parsing/indexing/sync must not block the reader UI.
- Avoid premature package/microservice/module splitting.
- Do not add mandatory cloud/account/network dependencies to core reading.
- Do not replace settled architecture without documenting the decision.
- Do not introduce one-off visual tokens/components when a design-system primitive should own the behavior.
- Do not trade readability/accessibility for fashion-driven effects.
- Prefer small coherent changes and tests over broad speculative rewrites.

## Definition of done for an agent patch

1. Requested change implemented.
2. Relevant tests/checks added or updated where applicable.
3. No invariant above violated.
4. Meaningful UI changes have a stated evidence/validation rationale.
5. `docs/PROJECT_STATE.md` updated.
6. Graph/decision/spec files updated if the patch affected them.
