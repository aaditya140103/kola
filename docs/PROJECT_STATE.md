# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked annotation management + anchor recovery.**

Kola imports local documents, renders real PDFs, restores position, extracts source-linked text/geometry, provides persistent local FTS search, source-linked PDF highlighting, annotation management, conservative anchor recovery, resolved annotation navigation, and now has CI-verified transient recovered highlight geometry. Flow remains disabled.

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
- `DocumentAdapter.resolveAnchor()` returns explicit `AnchorResolution` (D-026).
- `PdfAnchorResolver` conservatively verifies stored ranges/locator/logical range before quote+context fallback; ambiguous/missing matches stay unresolved.
- `AnnotationNavigationService` resolves Go to against the current source before Reader navigation (D-027).
- `AnchorResolution` can carry transient current-source geometry rebuilt from resolved PDF character ranges (D-028).
- `AnnotationGeometryRecoveryService` opens the document once, resolves all highlights, and exposes geometry only for successfully resolved annotations.
- Reader paints from recovered geometry rather than persisted rectangles; unresolved stale geometry is suppressed and the persisted `AnnotationAnchor` is never rewritten.
- PDF capabilities remain fidelity + text search + text selection + text annotations. Flow/ink/area annotations remain false.

## Annotation recovery path

```text
AnnotationAnchor
  -> current DocumentAdapter + DocumentHandle
  -> resolve current source location/range
  -> rebuild PDF-point geometry from current structured text
  -> AnchorResolution(sourceGeometry)
  -> transient recovered geometry map
  -> FidelityTextHighlight
  -> PDF paint callback

unresolved -> no paint
persisted anchor -> unchanged
```

## Important files

```text
lib/document/text/document_text_range_geometry.dart
lib/document/anchors/anchor_resolution.dart
lib/document/adapters/pdf/pdf_anchor_resolver.dart
lib/document/adapters/pdf/pdfrx_pdf_adapter.dart
lib/features/annotations/application/annotation_geometry_recovery_service.dart
lib/core/providers/annotation_providers.dart
lib/features/reader/presentation/reader_screen.dart
test/document/text/document_text_range_geometry_test.dart
test/features/annotations/annotation_geometry_recovery_service_test.dart
```

## Invariants

- Core reading/search/annotation requires no account/network.
- Original files are never modified.
- Generic Reader/annotation code does not import pdfrx.
- Delete uses a tombstone (`deletedAt`) for future sync compatibility.
- Persist source coordinates/ranges, never viewer/screen coordinates.
- Ambiguous anchor recovery must return unresolved rather than guess.
- Annotation Go to must resolve against the current source before moving Reader.
- Reader paint must use successfully resolved current-source geometry; unresolved stale rectangles are suppressed.
- Recovery never silently mutates the persisted annotation anchor.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #9 resolved annotation navigation is merged as `3c8d71be946b94577da3929f5daf1f37f2856c00`; exact-head CI run 124 passed. PR #10 implementation head CI run 127 passed Flutter 3.47.4 / Dart 3.13.3 dependency resolution, Drift generation, formatting, analyzer, pure geometry reconstruction tests, annotation geometry recovery tests, anchor/search/database tests, and the existing app smoke suite. This state synchronization is the only change after run 127 and requires one final exact-head CI pass before merge.

## Current risks / blockers

- Recovered geometry still needs physical validation on rotated/cropped/atypical PDFs and Linux + Android.
- Automatic recovery opens/extracts PDF text for annotations and may need caching/performance tuning on very annotation-heavy documents.
- Annotation management/navigation UI still needs physical UX validation.
- Scanned/image-only PDFs need local OCR for selection/search/recovery.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Merge recovered annotation geometry after exact-head CI.
2. Physically validate recovered highlight alignment on Linux + Android, including rotated/cropped PDFs.
3. Profile annotation recovery on documents with hundreds/thousands of highlights and add caching if measured.
4. Add annotation filters/export only after management UX is stable.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
