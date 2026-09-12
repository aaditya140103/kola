# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-13

## Current milestone

**Phase 2: PDF fidelity + search + source-linked annotation management/recovery; reader continuity and adaptive page layout.**

PDF open/back repair, outline/Contents, lazy thumbnails, and Fit Width / Fit Page are merged. This patch completes the next page-layout milestone by adding an optional adaptive two-page spread for expanded reader widths while preserving compact single-page reading.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + local FTS5.
- Managed/linked imports, streamed SHA-256 identity, real PDF fidelity and durable page/zoom resume.
- PDF source text/geometry, local search/source jumps, persistent highlights, notes/recolor/delete, conservative anchor recovery and transient recovered geometry.
- Handle-scoped page-text/quote caches and synthetic recovery profiling remain intact (D-026..D-031).
- Reader uses toolbar + Expanded source surface; compact toolbar and PDF page controls wrap.
- Home/Library push reader routes, matching Search; Back restores origin with Library fallback for direct routes.
- Loading/missing/error states can be left; resume-read/save failures degrade without trapping the reader.
- PDF outline capability is integrated: the active pdfrx document loads its outline lazily, nested nodes render in a Contents sheet, and selection uses the PDF destination directly through `goToDest`.
- PDF thumbnail navigation reuses the already-open `PdfDocument`, lazily builds visible previews with `PdfPageView`, marks the current page, and jumps through the existing viewer controller.
- PDF fit controls remain behind one compact Fit menu. Fit Width uses pdfrx's native width-fit matrix; Fit Page centers the active page at the smaller native width/height fit zoom.
- Expanded reader surfaces (>= 840 dp) expose a Page layout menu with Single page and Two-page spread. Single page remains the default.
- Two-page spread uses a PDF-local facing-page layout: page 1 is the right-side cover, then pages 2–3, 4–5, etc. share rows in left-to-right reading order.
- Spread preference is session-local and adaptive: narrowing below the expanded breakpoint renders single-page without discarding the preference; widening restores the spread. Document changes reset to single-page.
- Layout switches invalidate pdfrx and restore the active page, preserving navigation continuity and emitting the resulting fidelity position.
- Thumbnail rendering remains local/disposable; no persisted preview cache or generic-reader pdfrx dependency is introduced.
- Outline loading failure remains non-blocking/retryable; PDFs without an outline keep Contents disabled.
- Native PDF regression coverage now includes real rendering, fit commands, default single-page geometry, wide facing-page geometry, compact fallback, re-expansion, thumbnail/outline navigation, and rebuild behavior.
- PDF remains the only registered adapter/renderer. Import recognition does not imply reading support.

## Important files

- `lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart`
- `lib/document/adapters/pdf/pdf_page_layout.dart`
- `lib/document/adapters/pdf/pdf_thumbnail_sheet.dart`
- `lib/document/adapters/pdf/pdfrx_pdf_adapter.dart`
- `lib/features/reader/presentation/reader_screen.dart`
- `test/document/adapters/pdf/pdf_fidelity_renderer_test.dart`
- `test/document/registry/pdf_registration_test.dart`
- `test/support/simple_pdf.dart`
- `docs/PROJECT_GRAPH.md`, `UX_SPEC.md`, `UX_RESEARCH.md`, `UX_VALIDATION.md`

## Invariants

- Local reading/search/annotation requires no account/network; original files remain untouched.
- Generic reader code does not import pdfrx; PDF-engine destinations, previews, fit transforms, and facing-page layout stay inside the PDF renderer boundary.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Caches remain disposable and per handle; profiling remains local and ephemeral.
- Position progress stays separate from coverage and active reading time.
- Outline, thumbnail, fit, and page-layout controls are progressive disclosure around the document; none replaces or blocks readable source content.
- Thumbnail navigation reuses the active PDF document and must not create an unbounded app-owned preview cache.
- Fit and spread behavior use renderer-native/page-source geometry rather than screen-coordinate persistence.
- Compact widths must remain single-page even when spread is preferred.
- No new format, cloud, AI or study-system scope is introduced.

## Verification

The fit-controls main validation passed code generation, formatting, analyzer, and the full Flutter test suite on Flutter 3.47.4 / Dart 3.13.3. This spread patch adds native-PDF widget coverage at 900 dp and 600 dp to verify default single-page layout, opt-in facing pages, compact fallback, restoration on re-expansion, and continued thumbnail/outline/navigation behavior. Repository CI remains the authoritative gate for the new commit.

## UX rationale

The control follows Kola's evidence/UX rules: the document remains dominant, the less-frequent layout choice stays in progressive disclosure, and the option only appears when the reader surface is wide enough to support two pages without forcing the pattern on compact touch layouts. Physical validation is still required before treating the interaction as cross-platform complete.

## Risks / blockers

- Physical Linux/Android UX, predictive Back, large text, keyboard focus, thumbnail performance on very large PDFs, outline depth/size and atypical PDFs still need validation.
- Facing-page behavior is currently left-to-right with page 1 as cover; right-to-left/manga ordering and a no-cover pairing option are not implemented.
- Spread preference is not persisted across reader sessions; persist it only if usability testing shows clear value.
- Fit commands remain one-shot; sticky fit-on-resize should be added only if testing justifies it.
- Flow remains blocked on reading-order/source-map quality; scanned PDFs need OCR for selection/search.
- PDF metadata title fallback, `lastOpenedAt`, and missing managed-copy reimport repair remain follow-ups identified by the audit.
- Many unique stale quotes still warrant measurement before new indexing optimizations.

## Next recommended action

1. Physically validate import/open/scroll/select/Contents/Pages/Fit/Spread/Back/reopen on Linux + Android, including resize/rotation and keyboard focus.
2. Finish remaining reader-continuity follow-ups (metadata title fallback, `lastOpenedAt`, missing managed-copy reimport repair) before adding another format.
3. Add the many-unique-quotes recovery profile before reconstructed Flow work.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
