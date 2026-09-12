# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity View + durable resume + source text/geometry extraction.**

Kola imports content-addressed local documents, renders real PDFs through `pdfrx`/PDFium, restores page/zoom state, and now has a merged Kola-owned PDF text/geometry extraction pipeline. Search UI, text selection, annotations, and Flow remain intentionally disabled until their source-linked integrations are complete.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v1 with reactive repositories.
- Import: native picker -> format probe + streamed SHA-256 -> managed copy or linked source.
- Stable identity: `sha256:<hex>` (D-020); timestamps use UTC ISO-8601 text (D-019).
- PDF engine: `pdfrx ^2.6.1` / PDFium behind `PdfrxPdfAdapter` (D-021).
- PDF fidelity: progressive rendering, page navigation, zoom, keyboard navigation, durable resume.
- PDF resume: source page + progress + zoom + view mode through `ReadingState`; saves debounce 400 ms and flush on exit.
- `DocumentAdapter` exposes `extractTextGeometry()` returning Kola-owned `DocumentTextChunk`s.
- PDF extraction uses `PdfPage.loadStructuredText()` and maps engine objects through `PdfTextGeometryMapper`.
- `DocumentTextChunk` preserves page text, per-character rectangles, fragment ranges/bounds/direction, page extent, rotation, and source locator.
- Geometry remains native PDF points with bottom-left origin; screen/viewer coordinates are never source geometry (D-022).
- PDF `extractIndexableContent()` emits page-level `IndexChunk`s with stable PDF locations.
- PDF KDG emits conservative page `sourceVisualBlock` nodes at `FlowQuality.extracted`; no semantic paragraph claim yet.
- PDF capability flags still advertise fidelity only. Search/Flow/selection/annotations remain false until user-facing integrations exist.

## Extraction path

```text
PdfrxPdfHandle
  -> PdfPage.loadStructuredText()
  -> PdfPageText / fragments / character rectangles
  -> PdfTextGeometryMapper
  -> DocumentTextChunk
       -> IndexChunk
       -> KDG sourceVisualBlock
```

## Important files

```text
lib/document/text/document_text_geometry.dart
lib/document/registry/document_adapter.dart
lib/document/adapters/pdf/pdf_text_geometry_mapper.dart
lib/document/adapters/pdf/pdfrx_pdf_adapter.dart
test/document/adapters/pdf/pdf_text_geometry_mapper_test.dart
test/document/adapters/pdf/pdf_text_extraction_test.dart
```

## Invariants

- Core reading requires no account/network.
- Original files are never modified; managed copies are durable library data.
- Format/engine types stay behind Kola-owned adapters/models.
- Source geometry is source-native and stable; never store zoom/window/screen coordinates as annotation geometry.
- Extracted text does not imply correct semantic reading order or Flow readiness.
- Capability flags describe integrated Kola features, not underlying engine features.
- Flow/selection/annotations must resolve back to stable source locations before being enabled.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #4 is merged on `main` as `515224bf8953b9050e1b9e49d5abf7328e747ad9`. Its exact head passed Flutter CI on 2026-09-12 with Flutter 3.47.4 / Dart 3.13.3: dependency resolution, Drift generation, formatting, analyzer, mapper/geometry tests, and the full existing test suite are green. The generated real-PDF/PDFium integration test remains in the suite but runs only when `PDFIUM_PATH` points to a native libpdfium because standard `flutter test` runners do not bundle pdfrx native assets. Native/device extraction still requires that separate integration gate.

## Current risks / blockers

- PDF text fragment order comes from PDF extraction and is not yet a validated semantic reading order.
- Scanned/image-only PDFs will yield little/no text until local OCR exists.
- Search index persistence/query UI is not implemented yet despite `IndexChunk` production.
- Text selection and durable text anchors are not implemented yet.
- Physical PDF rendering/resume/extraction still needs hands-on platform testing.
- Native PDFium engine extraction test requires `PDFIUM_PATH` when run under `flutter test`.
- Password-protected/corrupt PDF UX remains basic.
- Native platform folders still need stable generation/commit on a Flutter-equipped machine.

## Next recommended action

1. Add a local persistent text index/search service consuming `IndexChunk`s.
2. Wire Reader search UI to page-level results and navigation; only then enable PDF `textSearch` capability.
3. Build source-linked text selection from page character indices + PDF rectangles.
4. Persist highlight/note anchors with quote/context + ranges + source geometry; then enable annotation capabilities.
5. Begin reconstructed PDF Flow only after reading-order/source-map quality tests exist.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
