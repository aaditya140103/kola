# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-13

## Current milestone

**Phase 2: PDF fidelity + search + source-linked annotation management/recovery; reader continuity and page-layout controls.**

The PDF-open/back-navigation repair, native outline/Contents navigation, and lazy thumbnail navigation are merged. This patch completes the next Phase 2 reader-continuity milestone by adding explicit Fit Width / Fit Page commands before two-page spread, new formats, or reconstructed Flow Mode.

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
- PDF fit controls are integrated behind one compact Fit menu. Fit Width uses pdfrx's native width-fit matrix for the active page; Fit Page combines the native width/height fit calculations and centers the active page at the smaller zoom.
- Fit commands animate through the existing `PdfViewerController`, emit the resulting fidelity position, and therefore participate in normal durable zoom persistence. They are commands, not sticky resize modes.
- Thumbnail rendering remains local and disposable; it introduces no persisted image cache or generic-reader dependency on pdfrx.
- Outline loading failure remains non-blocking and retryable; PDFs without an outline keep the Contents action disabled.
- Native PDF regression coverage includes a multi-page synthetic document, real page rendering, Fit Width / Fit Page behavior, thumbnail navigation, outline navigation, and viewer rebuild behavior.
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
- Generic reader code does not import pdfrx; PDF-engine destinations, previews, and fit transforms stay inside the PDF renderer boundary.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Caches remain disposable and per handle; profiling remains local and ephemeral.
- Position progress stays separate from coverage and active reading time.
- Outline, thumbnail, and fit controls are progressive disclosure around the document; none replaces or blocks the readable source.
- Thumbnail navigation reuses the active PDF document and must not create an unbounded app-owned preview cache.
- Fit actions use renderer-native page geometry rather than duplicate layout constants in Kola.
- No new format, cloud, AI or study-system scope is introduced.

## Verification

The thumbnail-navigation main validation passed code generation, formatting, analyzer, and the full Flutter test suite on Flutter 3.47.4 / Dart 3.13.3. This fit-controls patch adds native-PDF widget coverage on a wide viewport that verifies Fit Width and Fit Page produce the expected native controller zooms, then re-runs thumbnail navigation, outline navigation, and viewer rebuild behavior. Repository CI remains the authoritative gate for the new commit.

## Risks / blockers

- Physical Linux/Android UX, predictive Back, large text, keyboard focus, thumbnail performance on very large PDFs, outline depth/size and atypical PDFs still need validation.
- Two-page spread and remaining page-layout ergonomics are unfinished Phase 2 work.
- Fit commands are intentionally one-shot; a future sticky fit-on-resize mode should be added only if usability testing justifies it.
- Flow remains blocked on reading-order/source-map quality; scanned PDFs need OCR for selection/search.
- PDF metadata title fallback, `lastOpenedAt`, and missing managed-copy reimport repair remain follow-ups identified by the audit.
- Many unique stale quotes still warrant measurement before new indexing optimizations.

## Next recommended action

1. Physically validate import/open/scroll/select/Contents/Pages/Fit/Back/reopen on Linux + Android.
2. Add optional two-page spread for sufficiently wide reader windows as the next Phase 2 page-layout milestone.
3. Finish remaining continuity details; add the many-unique-quotes profile before reconstructed Flow work.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
