# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked annotation management + anchor recovery.**

Kola imports local documents, renders real PDFs, restores position, extracts source-linked text/geometry, provides persistent local FTS search, source-linked PDF highlighting, annotation management, conservative anchor recovery, and CI-verified resolved annotation navigation. Flow remains disabled.

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
- `AnnotationNavigationService` owns adapter open/resolve/close lifecycle and returns the current `AnchorResolution` (D-027).
- Annotation panel Go to returns the selected `Annotation`; Reader resolves it against the current source before generating `FidelityNavigationRequest`.
- Resolved fallback recovery navigates and surfaces a recovery message; unresolved anchors show a warning and do not move the Reader.
- PDF capabilities remain fidelity + text search + text selection + text annotations. Flow/ink/area annotations remain false.

## Annotation navigation path

```text
AnnotationPanel -> Annotation
  -> AnnotationNavigationService
  -> current DocumentAdapter + DocumentHandle
  -> resolveAnchor()
  -> AnchorResolution
     -> resolved: FidelityNavigationRequest
     -> unresolved: warning, no movement
  -> handle close
```

## Important files

```text
lib/features/annotations/application/annotation_navigation_service.dart
lib/features/annotations/presentation/annotation_panel.dart
lib/features/reader/presentation/reader_screen.dart
lib/document/anchors/anchor_resolution.dart
lib/document/adapters/pdf/pdf_anchor_resolver.dart
test/features/annotations/annotation_navigation_service_test.dart
```

## Invariants

- Core reading/search/annotation requires no account/network.
- Original files are never modified.
- Generic Reader/annotation code does not import pdfrx.
- Source anchors/geometry are not rewritten by recolor/note operations.
- Delete uses a tombstone (`deletedAt`) for future sync compatibility.
- Persist source coordinates/ranges, never viewer/screen coordinates.
- Ambiguous anchor recovery must return unresolved rather than guess.
- Annotation Go to must resolve against the current source before moving Reader.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #8 anchor recovery is merged and exact-head CI run 120 passed. Current `feat/annotation-resolved-navigation` implementation passed Flutter CI run 123 on Flutter 3.47.4 / Dart 3.13.3: dependency resolution, Drift generation, formatting, analyzer, navigation-service lifecycle tests, anchor/search/database tests, and the existing app smoke suite all passed. This state-file synchronization is the only change after run 123 and requires one final exact-head CI pass before merge.

## Current risks / blockers

- Recovered source location is used for navigation, but changed-document PDF highlight geometry is not yet regenerated/repainted at the recovered location.
- Annotation management/navigation UI still needs physical UX validation.
- Physical PDF drag-selection/highlight alignment needs Linux + Android validation first.
- Rotated/cropped/atypical PDF highlight geometry needs hands-on validation.
- Scanned/image-only PDFs need local OCR for selection/search/recovery.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Merge resolved annotation navigation after exact-head CI.
2. Regenerate source geometry for confidently recovered PDF anchors after source changes.
3. Physically validate Reader annotation UX on Linux + Android.
4. Add annotation filters/export only after management UX is stable.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
