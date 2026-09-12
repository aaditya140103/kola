# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked annotation management.**

Kola imports local documents, renders real PDFs, restores position, extracts source-linked text/geometry, provides persistent local FTS search, and has merged source-linked PDF highlighting. `feat/annotation-management` adds list/jump/recolor/note/delete management for those durable annotations. Flow remains disabled.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + app-owned FTS5 search.
- Import: format probe + streamed SHA-256 -> managed copy or explicit linked source.
- PDF engine: `pdfrx ^2.6.1` / PDFium behind Kola adapter/renderer boundaries.
- PDF fidelity: progressive render, page/zoom/navigation, durable resume.
- PDF source extraction: structured text + native PDF-point geometry.
- Search: persistent local FTS5, lazy freshness, global + reader search, source-page jump.
- PDF selection -> `DocumentTextSelection` -> hybrid `AnnotationAnchor` -> SQLite -> live highlight repaint.
- `AnnotationManagementService` recolors highlights, edits/clears notes, and soft-deletes annotations while preserving source anchors (D-025).
- `AnnotationPanel` watches live document annotations and provides quote/location preview, Go to, six highlight colors, note edit, and delete confirmation.
- Annotation Go to emits the existing `DocumentLocation` and Reader uses the same `FidelityNavigationRequest` path as search.
- Delete writes `deletedAt`; `watchForDocument()` already filters tombstones, so deletion removes the highlight from the live reader without hard-destroying sync history.
- Reader search UI was extracted into `reader_search_sheet.dart` to keep Reader orchestration smaller.
- PDF capabilities remain fidelity + text search + text selection + text annotations. Flow/ink/area annotations remain false.

## Annotation paths

```text
CREATE
PDF selection -> DocumentTextSelection -> AnnotationCreationService
-> AnnotationAnchor -> AnnotationRepository -> SQLite -> live repaint

MANAGE
AnnotationPanel -> AnnotationManagementService -> AnnotationRepository
-> SQLite -> annotationsProvider -> panel + PDF repaint

NAVIGATE
Annotation sourceLocator -> FidelityNavigationRequest -> PDF source page
```

## Important files

```text
lib/features/annotations/application/annotation_creation_service.dart
lib/features/annotations/application/annotation_management_service.dart
lib/features/annotations/presentation/annotation_panel.dart
lib/features/annotations/data/drift_annotation_repository.dart
lib/features/reader/presentation/reader_screen.dart
lib/features/reader/presentation/reader_search_sheet.dart
lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart
```

## Invariants

- Core reading/search/annotation requires no account/network.
- Original files are never modified.
- Generic Reader/annotation code does not import pdfrx.
- Source anchors/geometry are not rewritten by recolor/note operations.
- Delete uses a tombstone (`deletedAt`) for future sync compatibility.
- Persist source coordinates/ranges, never viewer/screen coordinates.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #6 PDF highlighting is merged and passed exact-head Flutter CI run 110 on Flutter 3.47.4 / Dart 3.13.3. Current annotation-management branch adds command-layer and SQLite tests for recolor, note edit, revision increments, anchor preservation, and tombstone filtering. Full CI for this branch is required before merge.

## Current risks / blockers

- Annotation management UI needs analyzer/widget validation in CI and physical UX testing.
- Physical PDF drag-selection/highlight alignment still needs Linux + Android validation first.
- Rotated/cropped/atypical PDF highlight geometry needs hands-on validation.
- `resolveAnchor()` still returns the stored locator directly; quote/context recovery across changed source revisions is not implemented.
- Scanned/image-only PDFs need local OCR for selection/search.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Pass CI and merge annotation-management branch.
2. Physically validate Reader annotations on Linux + Android.
3. Strengthen PDF `resolveAnchor()` with quote/context fallback for changed document revisions.
4. Add annotation filters/export only after management UX is stable.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
