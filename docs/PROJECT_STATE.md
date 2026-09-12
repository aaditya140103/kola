# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF fidelity + search + source-linked annotation management/recovery; reader display and navigation repair.**

PDF display and ordinary Back are implemented functionality, not deferred features. The reader audit reproduced a collapsed viewport (toolbar-sized Stack), missing navigation history from Home/Library, inaccessible exits in loading/direct/error routes, and compact-control overflows. This patch repairs those flows before adding new formats or Flow Mode.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + local FTS5; no schema changes in this repair.
- Managed/linked imports, streamed SHA-256 identity, real PDF fidelity and durable page/zoom resume.
- PDF source text/geometry, local search/source jumps, persistent highlights, notes/recolor/delete, conservative anchor recovery and transient recovered geometry.
- Handle-scoped page-text/quote caches and synthetic recovery profiling remain intact (D-026..D-031).
- Reader uses toolbar + Expanded source surface; compact toolbar and PDF page controls wrap.
- Home/Library push reader routes, matching Search; Back restores origin with Library fallback for direct routes.
- Back remains visible; loading/missing/error states can be left. Focus/auto-hide remains deferred until reliable escape interactions are tested.
- Resume-read errors show a warning while rendering the source; position-save failures do not trap exit. Repository access for disposal flushes is captured while mounted.
- Native PDF tests now resolve Flutter's built asset explicitly rather than silently skipping extraction.
- PDF remains the only registered adapter/renderer. Import recognition does not imply reading support.

## Important files

- `lib/features/reader/presentation/reader_screen.dart`
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/library/presentation/library_screen.dart`
- `lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart`
- `test/features/reader/reader_navigation_test.dart`
- `test/document/adapters/pdf/pdf_fidelity_renderer_test.dart`
- `test/document/adapters/pdf/pdf_text_extraction_test.dart`
- `test/support/native_pdfium.dart`, `test/support/simple_pdf.dart`
- `docs/READER_AUDIT.md`, `PROJECT_GRAPH.md`, `UX_SPEC.md`, `UX_VALIDATION.md`, `README.md`

## Invariants

- Local reading/search/annotation requires no account/network; original files remain untouched.
- Generic reader code does not import pdfrx; app-owned models remain at adapter boundaries.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Caches remain disposable and per handle; profiling remains local and ephemeral.
- Position progress stays separate from coverage and active reading time.
- No new format, cloud, AI or study-system scope is introduced.

## Verification

The pre-repair main CI run 144 passed, but only an empty-Home smoke test covered UI, and native PDF extraction was skipped by default. New tests reproduced the reader layout/navigation bugs before repair. Local validation uses Flutter 3.47.1 / Dart 3.13.1, dependency resolution, Drift generation, analyzer, full suite, and real PDFium page rendering/text extraction. Analyzer and all 76 tests passed with no skips, and an isolated Linux release build succeeded with bundled PDFium/SQLite. Final results and platform limits are recorded in `READER_AUDIT.md`.

## Risks / blockers

- Physical Linux/Android UX, predictive Back, large text, keyboard focus and atypical PDFs still need validation.
- Flow remains blocked on reading-order/source-map quality; scanned PDFs need OCR for selection/search.
- Native tests expect Flutter's `build/native_assets/<host>` layout or an explicit `PDFIUM_PATH`; changes in SDK output layout may require updating the test helper.
- PDF metadata title fallback, `lastOpenedAt`, and missing managed-copy reimport repair remain follow-ups identified by the audit.
- Many unique stale quotes still warrant measurement before new indexing optimizations.

## Next recommended action

1. Physically validate import/open/scroll/select/Back/reopen on Linux + Android.
2. Finish reader continuity details and remaining Phase 2 navigation/outline/thumbnail work.
3. Add the many-unique-quotes profile; begin reconstructed Flow only after source-map/reading-order quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
