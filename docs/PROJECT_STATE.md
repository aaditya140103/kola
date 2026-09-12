# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-13

## Current milestone

**Phase 2: PDF fidelity + search + source-linked annotation management/recovery; reader continuity and structure navigation.**

The PDF-open/back-navigation repair and native outline/Contents navigation are merged. The current patch completes the next Phase 2 structure-navigation milestone by adding lazy PDF thumbnail navigation before fit controls, new formats, or reconstructed Flow Mode.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + local FTS5.
- Managed/linked imports, streamed SHA-256 identity, real PDF fidelity and durable page/zoom resume.
- PDF source text/geometry, local search/source jumps, persistent highlights, notes/recolor/delete, conservative anchor recovery and transient recovered geometry.
- Handle-scoped page-text/quote caches and synthetic recovery profiling remain intact (D-026..D-031).
- Reader uses toolbar + Expanded source surface; compact toolbar and PDF page controls wrap.
- Home/Library push reader routes, matching Search; Back restores origin with Library fallback for direct routes.
- Loading/missing/error states can be left; resume-read/save failures degrade without trapping the reader.
- PDF outline capability is integrated: the active pdfrx document loads its outline lazily, the navigation bar exposes Contents only when usable, nested outline nodes render in a sheet, and selection uses the PDF destination directly through `goToDest`.
- PDF thumbnail navigation is integrated: the Pages action reuses the already-open `PdfDocument`, lazily builds visible previews with `PdfPageView`, marks the current page, and jumps through the existing viewer controller without reopening the file.
- Thumbnail rendering remains local and disposable; it introduces no persisted image cache or generic-reader dependency on pdfrx.
- Outline loading failure remains non-blocking and retryable; PDFs without an outline keep the Contents action disabled.
- Native PDF regression coverage includes a multi-page synthetic document, real page rendering, thumbnail navigation, outline navigation, and viewer rebuild behavior.
- PDF remains the only registered adapter/renderer. Import recognition does not imply reading support.

## Important files

- `lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart`
- `lib/document/adapters/pdf/pdf_thumbnail_sheet.dart`
- `lib/document/adapters/pdf/pdfrx_pdf_adapter.dart`
- `lib/features/reader/presentation/reader_screen.dart`
- `test/document/adapters/pdf/pdf_fidelity_renderer_test.dart`
- `test/document/registry/pdf_registration_test.dart`
- `test/support/simple_pdf.dart`
- `docs/PROJECT_GRAPH.md`, `UX_SPEC.md`, `UX_RESEARCH.md`, `UX_VALIDATION.md`

## Invariants

- Local reading/search/annotation requires no account/network; original files remain untouched.
- Generic reader code does not import pdfrx; PDF-engine destinations and preview widgets stay inside the PDF renderer boundary.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Caches remain disposable and per handle; profiling remains local and ephemeral.
- Position progress stays separate from coverage and active reading time.
- Outline and thumbnail navigation are progressive disclosure around the document; neither replaces or blocks the readable source.
- Thumbnail navigation reuses the active PDF document and must not create an unbounded app-owned preview cache.
- No new format, cloud, AI or study-system scope is introduced.

## Verification

The previous outline-navigation main validation passed code generation, formatting, analyzer, and the full Flutter test suite on Flutter 3.47.4 / Dart 3.13.3. This thumbnail patch adds multi-page native-PDF widget coverage for opening Pages, rendering lazy `PdfPageView` previews, selecting page 2, returning through outline navigation, and preserving viewer rebuild behavior. Repository CI remains the authoritative gate for the new commit.

## Risks / blockers

- Physical Linux/Android UX, predictive Back, large text, keyboard focus, thumbnail performance on very large PDFs, outline depth/size and atypical PDFs still need validation.
- Fit-width/fit-page controls and later two-page spread remain unfinished Phase 2 work.
- Flow remains blocked on reading-order/source-map quality; scanned PDFs need OCR for selection/search.
- PDF metadata title fallback, `lastOpenedAt`, and missing managed-copy reimport repair remain follow-ups identified by the audit.
- Many unique stale quotes still warrant measurement before new indexing optimizations.

## Next recommended action

1. Physically validate import/open/scroll/select/Contents/Pages/Back/reopen on Linux + Android.
2. Add fit-width / fit-page controls as the next Phase 2 reader-continuity milestone.
3. Finish remaining page-layout details; add the many-unique-quotes profile before reconstructed Flow work.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
