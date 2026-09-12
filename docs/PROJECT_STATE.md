# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-13

## Current milestone

**Phase 2: PDF fidelity + search + source-linked annotation management/recovery; reader continuity and adaptive page layout.**

PDF open/back repair, outline/Contents, lazy thumbnails, Fit controls, and adaptive two-page spread are merged. This patch finishes the audit-identified reader-continuity cleanup: stable human PDF titles for managed copies, reader-open recency tracking, and repair of missing managed copies on reimport.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + local FTS5.
- Managed/linked imports, streamed SHA-256 identity, real PDF fidelity and durable page/zoom resume.
- PDF source text/geometry, local search/source jumps, persistent highlights, notes/recolor/delete, conservative anchor recovery and transient recovered geometry.
- Handle-scoped page-text/quote caches and synthetic recovery profiling remain intact (D-026..D-031).
- Reader uses toolbar + Expanded source surface; compact toolbar and PDF page controls wrap.
- Home/Library push reader routes, matching Search; Back restores origin with Library fallback for direct routes.
- PDF outline, lazy thumbnail navigation, Fit Width / Fit Page, and optional >= 840 dp facing-page spread remain integrated inside the PDF renderer boundary.
- Managed PDF metadata fallback now uses the original file URI name rather than the hash-named managed copy path. The managed source is still resolved first, so unreadable copies are not hidden by metadata fallback.
- Entering a resolved reader document records `documents.last_opened_at` once per reader instance. The write is non-blocking and failures never prevent reading.
- `lastOpenedAt` is a recency signal only: opening a document does not increment document revision or overwrite structural `updatedAt`. Existing Library/Home ordering reacts through document-table invalidation.
- Reimporting the exact same managed source now verifies that its managed file still exists before returning `alreadyPresent`. A missing copy is recreated through `DocumentSourceStorage.prepare`, preserves document identity/history, and returns `sourceRepaired`.
- A successful repair preserves `importedAt` and `lastOpenedAt`, increments revision as a source repair, refreshes metadata/file size, and keeps the original file untouched.
- Thumbnail rendering remains local/disposable; no persisted preview cache or generic-reader pdfrx dependency is introduced.
- PDF remains the only registered adapter/renderer. Import recognition does not imply reading support.

## Important files

- `lib/document/import/document_import_service.dart`
- `lib/document/import/document_source_storage.dart`
- `lib/document/adapters/pdf/pdfrx_pdf_adapter.dart`
- `lib/features/library/domain/document_repository.dart`
- `lib/features/library/data/drift_document_repository.dart`
- `lib/features/library/presentation/import_document_button.dart`
- `lib/features/reader/presentation/reader_screen.dart`
- `test/document/import/document_import_service_test.dart`
- `test/document/registry/pdf_registration_test.dart`
- `test/core/repositories/repository_integration_test.dart`
- `test/features/reader/reader_navigation_test.dart`
- `docs/PROJECT_GRAPH.md`

## Invariants

- Local reading/search/annotation requires no account/network; original files remain untouched.
- Generic reader code does not import pdfrx; PDF-engine destinations, previews, fit transforms, facing-page layout, and PDF metadata fallback stay behind PDF boundaries.
- Stable content hash remains document identity; source repair does not create a duplicate library item.
- Managed-copy repair only runs after the user reselects/imports matching bytes; Kola does not silently recover from arbitrary external files.
- Opening recency is independent of source/metadata revision and reading-position progress.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Caches remain disposable and per handle; profiling remains local and ephemeral.
- Position progress stays separate from coverage and active reading time.
- Compact widths must remain single-page even when spread is preferred.
- No new format, cloud, AI or study-system scope is introduced.

## Verification

The previous adaptive-spread main validation passed code generation, formatting, analyzer, and the full Flutter test suite on Flutter 3.47.4 / Dart 3.13.3. This continuity patch adds regressions for original-name PDF metadata, managed-copy deletion/reimport repair/idempotence, `lastOpenedAt` persistence and recent-order invalidation without revision mutation, and one-shot reader-open recording. Repository CI is the authoritative gate for the new commit.

## Risks / blockers

- Physical Linux/Android UX, predictive Back, large text, keyboard focus, thumbnail performance on very large PDFs, outline depth/size and atypical PDFs still need validation.
- Managed-copy repair currently requires explicit reimport of matching content; a dedicated missing-source recovery UI is not yet implemented.
- Facing-page behavior is currently left-to-right with page 1 as cover; right-to-left/manga ordering and a no-cover pairing option are not implemented.
- Spread preference is not persisted across reader sessions; persist it only if usability testing shows clear value.
- Fit commands remain one-shot; sticky fit-on-resize should be added only if testing justifies it.
- Flow remains blocked on reading-order/source-map quality; scanned PDFs need OCR for selection/search.
- Many unique stale quotes still warrant measurement before new indexing optimizations.

## Next recommended action

1. Physically validate import/open/scroll/select/Contents/Pages/Fit/Spread/Back/reopen on Linux + Android, including deleting a managed copy and repairing it through reimport.
2. Add the many-unique-quotes recovery profile before another recovery/index optimization.
3. After continuity validation, choose the next format milestone through the shared adapter/graph boundaries; do not jump to reconstructed PDF Flow before source-map/reading-order quality is ready.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
