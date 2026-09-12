# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked annotation management + anchor recovery.**

Kola imports local documents, renders real PDFs, restores position, extracts source-linked text/geometry, provides persistent local FTS search, source-linked PDF highlighting, annotation management, conservative anchor recovery, resolved annotation navigation, recovered highlight geometry, and now has a handle-scoped PDF text cache for recovery/indexing performance. Flow remains disabled.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + app-owned FTS5 search.
- Import: format probe + streamed SHA-256 -> managed copy or explicit linked source.
- PDF engine: `pdfrx ^2.6.1` / PDFium behind Kola adapter/renderer boundaries.
- PDF fidelity: progressive render, page/zoom/navigation, durable resume.
- PDF source extraction: structured text + native PDF-point geometry.
- Search: persistent local FTS5, lazy freshness, global + reader search, source-page jump.
- PDF selection -> hybrid `AnnotationAnchor` -> SQLite -> live highlight repaint.
- Annotation panel supports list/jump/recolor/note/delete; edits preserve anchors and deletes use tombstones.
- Conservative `AnchorResolution` recovery + resolved navigation + transient recovered geometry are merged (D-026..D-028).
- `PdfrxPdfHandle` owns a disposable `PdfPageTextCache` (D-029): repeated/concurrent reads of one page share one extraction future; failures are evicted; close clears the cache.
- `AnnotationGeometryRecoveryService` opens one handle for the full highlight batch, so hundreds of annotations can reuse page extraction across the batch instead of reloading the same page per annotation.
- Reader paints only successfully resolved current-source geometry; unresolved stale geometry is suppressed and persisted anchors remain unchanged.
- PDF capabilities remain fidelity + text search + text selection + text annotations. Flow/ink/area annotations remain false.

## Recovery performance path

```text
AnnotationGeometryRecoveryService
  -> open one PdfrxPdfHandle
  -> resolve annotation A -> page N -> PdfPageTextCache
  -> resolve annotation B -> page N -> same cached/in-flight chunk
  -> resolve annotation C -> page M -> one new extraction
  -> close handle -> clear cache
```

## Important files

```text
lib/document/adapters/pdf/pdf_page_text_cache.dart
lib/document/adapters/pdf/pdfrx_pdf_adapter.dart
lib/features/annotations/application/annotation_geometry_recovery_service.dart
lib/document/text/document_text_range_geometry.dart
test/document/adapters/pdf/pdf_page_text_cache_test.dart
test/features/annotations/annotation_geometry_recovery_service_test.dart
```

## Invariants

- Core reading/search/annotation requires no account/network.
- Original files are never modified.
- Generic Reader/annotation code does not import pdfrx.
- Persist source coordinates/ranges, never viewer/screen coordinates.
- Ambiguous anchor recovery returns unresolved rather than guessing.
- Reader paint uses only successfully resolved current-source geometry.
- Recovery never silently mutates the persisted annotation anchor.
- PDF text cache is scoped to one open handle; no unbounded global cache.
- Failed page extraction is evicted so a later read can retry.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #10 is merged on `main` as squash commit `af92f5373bcd7f46cf157be8f65959a3ce599487`; implementation-head run 127 and exact-head run 128 passed. PR #11 implementation-head CI run 131 passed Flutter 3.47.4 / Dart 3.13.3 dependency resolution, Drift generation, formatting, analyzer, all new PDF page-cache tests, annotation recovery tests, search/database tests, and the existing app smoke suite. This state synchronization is the only change after run 131 and requires one final exact-head CI pass before merge.

## Current risks / blockers

- Recovered geometry still needs physical validation on rotated/cropped/atypical PDFs and Linux + Android.
- Handle-scoped caching removes duplicate extraction within one open session, but recovery over very large documents may still spend CPU scanning many cached page strings for quote fallback; profile before adding indexing/global caches.
- Annotation management/navigation UI still needs physical UX validation.
- Scanned/image-only PDFs need local OCR for selection/search/recovery.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Merge handle-scoped recovery caching after exact-head CI.
2. Physically validate recovered highlight alignment on Linux + Android, including rotated/cropped PDFs.
3. Profile quote-fallback recovery on documents with hundreds/thousands of highlights before adding further optimization.
4. Add annotation filters/export only after management UX is stable.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
