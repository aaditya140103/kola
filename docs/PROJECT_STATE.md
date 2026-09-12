# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked text highlighting.**

Kola imports content-addressed local documents, renders real PDFs through `pdfrx`/PDFium, restores page/zoom state, extracts source-linked text/geometry, provides persistent local full-text search, and now has a merged source-linked PDF text-selection + persistent-highlight path. Flow and note-editing UI remain disabled.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 with app-owned FTS5 search tables/state.
- Import: native picker -> format probe + streamed SHA-256 -> managed copy or linked source.
- Stable identity: `sha256:<hex>` (D-020); timestamps use UTC ISO-8601 text (D-019).
- Successful imports warm the local search index without blocking import.
- PDF engine: `pdfrx ^2.6.1` / PDFium behind `PdfrxPdfAdapter` (D-021).
- PDF fidelity: progressive rendering, page navigation, zoom, keyboard navigation, durable resume.
- PDF extraction: structured page text -> Kola `DocumentTextChunk`; geometry remains native PDF points (D-022).
- Search: persistent SQLite FTS5, lazy freshness checks, global + reader search, source-page navigation (D-023).
- PDF selection: pdfrx `PdfPageTextRange`/fragment rectangles -> Kola `DocumentTextSelection`.
- `AnnotationCreationService` converts a selection into the existing hybrid `AnnotationAnchor` with quote/context, single-page logical offsets, per-page fallback ranges, and PDF-point source geometry (D-024).
- Highlight IDs use UUID v4 through an explicit `uuid ^4.6.0` direct dependency.
- Reader watches durable annotations and maps highlights to format-neutral `FidelityTextHighlight` records.
- PDF renderer repaints persisted highlight rectangles through page paint callbacks; no viewer/screen coordinates are stored.
- PDF context menu adds `Highlight` only when selected text/ranges are accessible.
- PDF capability advertises fidelity, search, text selection, and text annotations; area/ink annotations and Flow remain false.

## Highlight path

```text
pdfrx text selection
  -> PdfPageTextRange + fragment bounds
  -> DocumentTextSelection
  -> AnnotationCreationService
  -> AnnotationAnchor
  -> AnnotationRepository
  -> SQLite
  -> annotationsProvider
  -> FidelityTextHighlight
  -> PDF page paint callback
```

## Important files

```text
lib/document/text/document_text_selection.dart
lib/document/fidelity/document_fidelity_renderer.dart
lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart
lib/features/annotations/application/annotation_creation_service.dart
lib/features/annotations/data/drift_annotation_repository.dart
lib/core/providers/annotation_providers.dart
lib/features/reader/presentation/reader_screen.dart
test/features/annotations/annotation_creation_service_test.dart
test/features/annotations/annotation_geometry_persistence_test.dart
test/document/registry/pdf_registration_test.dart
```

## Invariants

- Core reading/search/annotation requires no account/network.
- Original files are never modified.
- Generic Reader/annotation code does not import pdfrx.
- Persist source locators/text ranges/PDF points, never screen coordinates.
- Highlight anchors preserve exact quote + context in addition to geometry.
- Multi-page selection preserves per-page source ranges and rectangles.
- Capability flags describe integrated Kola behavior, not package primitives.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #6 is merged on `main` as squash commit `0dfe9d2071b1dce0df3cf70841b15ef0e2feef5a`. Run 109 passed Flutter 3.47.4 / Dart 3.13.3 dependency resolution, Drift generation, formatting, analyzer, the single-page highlight-anchor test, multi-page fallback-range test, SQLite geometry round-trip test, updated PDF capability contract, search/database tests, and the existing app smoke suite. Final exact-head run 110 also passed generation, formatting, analyzer, and the full test suite before merge. The native PDFium extraction test remains intentionally skipped in CI unless `PDFIUM_PATH` is supplied.

## Current risks / blockers

- Physical drag-selection/selection-handle behavior must be tested on touch and desktop pointer platforms.
- Highlight paint alignment must be verified on rotated/cropped/atypical PDF pages.
- Scanned/image-only PDFs have no selectable text until local OCR exists.
- Existing annotations have no edit/delete/color UI in the Reader yet.
- Text notes/margin notes are not integrated yet.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Physically validate selection and highlight alignment on Linux + Android first, then other targets.
2. Add annotation management: list, jump, recolor, delete, note attachment.
3. Strengthen `resolveAnchor()` with quote/context fallback when document revisions change.
4. Begin reconstructed PDF Flow only after reading-order/source-map quality tests exist.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
