# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked annotation management + anchor recovery.**

Kola imports local documents, renders real PDFs, restores position, extracts source-linked text/geometry, provides persistent local FTS search, source-linked PDF highlighting, annotation management, and merged conservative annotation-anchor recovery after source revisions. Flow remains disabled.

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
- `DocumentAdapter.resolveAnchor()` returns explicit `AnchorResolution` rather than a guessed nullable location (D-026).
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

PR #8 is merged on `main` as squash commit `81fea2f8c97110b46589958d695f0c498e58554c`. Run 118 surfaced one stale search-test fake using the old nullable resolver contract; production code was unaffected. After updating that fake, corrected run 119 passed Flutter 3.47.4 / Dart 3.13.3 dependency resolution, Drift generation, formatting, analyzer, all new anchor recovery tests, search/database tests, and the existing app smoke suite. Final exact synchronized head run 120 also passed every CI stage before merge. The native PDFium extraction test remains intentionally skipped unless `PDFIUM_PATH` is supplied.

## Current risks / blockers

- Anchor recovery currently resolves a reliable source location; recovered PDF geometry is not yet regenerated for changed documents.
- Reader annotation navigation still uses the stored locator directly instead of consuming `AnchorResolution` and surfacing unresolved state.
- Annotation management UI still needs physical UX validation.
- Physical PDF drag-selection/highlight alignment needs Linux + Android validation first.
- Rotated/cropped/atypical PDF highlight geometry needs hands-on validation.
- Scanned/image-only PDFs need local OCR for selection/search/recovery.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Wire `AnchorResolution` into annotation navigation so Go to uses recovery and unresolved annotations are surfaced safely.
2. Regenerate source geometry for confidently recovered PDF anchors after source changes.
3. Physically validate Reader annotation UX on Linux + Android.
4. Add annotation filters/export only after management UX is stable.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
