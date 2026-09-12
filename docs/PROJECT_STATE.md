# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked annotation management + anchor recovery.**

Kola imports local documents, renders real PDFs, restores position, extracts source-linked text/geometry, provides persistent local FTS search, source-linked PDF highlighting, annotation management, and now has a branch implementation for conservative annotation-anchor recovery after source revisions. Flow remains disabled.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + app-owned FTS5 search.
- Import: format probe + streamed SHA-256 -> managed copy or explicit linked source.
- PDF engine: `pdfrx ^2.6.1` / PDFium behind Kola adapter/renderer boundaries.
- PDF fidelity: progressive render, page/zoom/navigation, durable resume.
- PDF source extraction: structured text + native PDF-point geometry.
- Search: persistent local FTS5, lazy freshness, global + reader search, source-page jump.
- PDF selection -> `DocumentTextSelection` -> hybrid `AnnotationAnchor` -> SQLite -> live highlight repaint.
- Annotation panel supports list/jump/recolor/note/delete; edits preserve anchors and deletes use tombstones.
- `DocumentAdapter.resolveAnchor()` now returns explicit `AnchorResolution` rather than a guessed nullable location (D-026).
- `PdfAnchorResolver` resolution order: verify multi-page stored fallback ranges -> verify stored page/range -> verify logical range -> search exact quote and disambiguate with prefix/suffix context -> unresolved.
- Ambiguous duplicate quotes and missing quotes remain unresolved; Kola never silently attaches an annotation to uncertain text.
- PDF capabilities remain fidelity + text search + text selection + text annotations. Flow/ink/area annotations remain false.

## Anchor recovery path

```text
AnnotationAnchor
  -> verify stored fallback/source ranges against exact quote
  -> verify logical range
  -> exact quote search across PDF pages
  -> prefix/suffix context disambiguation
  -> AnchorResolution(resolved + strategy + confidence)
     OR AnchorResolution(unresolved + reason)
```

## Important files

```text
lib/document/anchors/anchor_resolution.dart
lib/document/adapters/pdf/pdf_anchor_resolver.dart
lib/document/adapters/pdf/pdfrx_pdf_adapter.dart
lib/document/registry/document_adapter.dart
test/document/adapters/pdf/pdf_anchor_resolver_test.dart
lib/features/annotations/presentation/annotation_panel.dart
```

## Invariants

- Core reading/search/annotation requires no account/network.
- Original files are never modified.
- Generic Reader/annotation code does not import pdfrx.
- Source anchors/geometry are not rewritten by recolor/note operations.
- Delete uses a tombstone (`deletedAt`) for future sync compatibility.
- Persist source coordinates/ranges, never viewer/screen coordinates.
- Ambiguous anchor recovery must return unresolved rather than guess.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #7 annotation management is merged and exact-head CI run 115 passed. Current `feat/pdf-anchor-recovery` branch adds explicit resolution results and pure resolver tests for unchanged anchors, shifted text, cross-page movement, ambiguous duplicate quotes, missing quotes, and stored multi-page fallback ranges. Full CI is required before merge.

## Current risks / blockers

- Anchor recovery currently resolves a reliable source location; recovered PDF geometry is not yet regenerated for changed documents.
- Annotation management UI still needs physical UX validation.
- Physical PDF drag-selection/highlight alignment needs Linux + Android validation first.
- Rotated/cropped/atypical PDF highlight geometry needs hands-on validation.
- Scanned/image-only PDFs need local OCR for selection/search/recovery.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Pass CI and merge PDF anchor recovery.
2. Integrate resolved/unresolved state into annotation navigation/render diagnostics where needed.
3. Physically validate Reader annotation UX on Linux + Android.
4. Add annotation filters/export only after management UX is stable.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
