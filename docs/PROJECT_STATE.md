# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + resume + source text/geometry + persistent local search.**

Kola imports content-addressed local documents, renders real PDFs through `pdfrx`/PDFium, restores page/zoom state, extracts source-linked text/geometry, and now has a verified on-device persistent full-text search path. Text selection, annotations, and Flow remain intentionally disabled.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2; v2 adds app-owned FTS5 search tables/state + document-delete cleanup trigger.
- Import: native picker -> format probe + streamed SHA-256 -> managed copy or linked source.
- Stable identity: `sha256:<hex>` (D-020); timestamps use UTC ISO-8601 text (D-019).
- Successful imports start a non-blocking search-index warm-up; failure never fails the import. Search still verifies freshness on demand.
- PDF engine: `pdfrx ^2.6.1` / PDFium behind `PdfrxPdfAdapter` (D-021).
- PDF fidelity: progressive rendering, page navigation, zoom, keyboard navigation, durable resume.
- PDF resume: source page + progress + zoom + view mode through `ReadingState`; saves debounce 400 ms and flush on exit.
- PDF extraction: `PdfPage.loadStructuredText()` -> `PdfTextGeometryMapper` -> Kola `DocumentTextChunk`.
- Geometry stays native PDF points with bottom-left origin (D-022).
- PDF `extractIndexableContent()` emits page-level `IndexChunk`s with stable PDF locators.
- `DriftSearchRepository` persists document metadata + content in SQLite FTS5 and stores index freshness separately.
- `DocumentSearchService` lazily indexes stale documents and reuses an index when document revision + extractor version match.
- Global Search searches local metadata/content; Reader Search returns content hits only.
- Search results carry `DocumentLocation`; Reader converts them to format-neutral `FidelityNavigationRequest`s.
- PDF renderer resolves search jumps to exact source pages without exposing `PdfViewerController` outside the adapter renderer.
- PDF capability advertises `fidelityView` + `textSearch`. Flow/text selection/text annotations remain false.

## Search path

```text
KolaDocument
  -> revision/extractor freshness check
  -> DocumentAdapter.extractIndexableContent()
  -> IndexChunk
  -> DocumentSearchService
  -> DriftSearchRepository
  -> SQLite FTS5
  -> SearchHit + DocumentLocation
  -> FidelityNavigationRequest
  -> PDF source page
```

## Important files

```text
lib/core/database/kola_database.dart
lib/features/search/domain/search_models.dart
lib/features/search/domain/search_repository.dart
lib/features/search/data/drift_search_repository.dart
lib/features/search/application/document_search_service.dart
lib/core/providers/search_providers.dart
lib/features/search/presentation/search_screen.dart
lib/features/reader/presentation/reader_screen.dart
lib/document/fidelity/document_fidelity_renderer.dart
lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart
```

## Invariants

- Core reading/search requires no account/network.
- Original files are never modified; managed copies are durable library data.
- Search is format-neutral and consumes `IndexChunk`; no PDF-specific schema columns.
- Search locators are source locators, never screen/viewer coordinates.
- Global search may include metadata; in-reader search uses content hits only.
- Search index failure for one document must not block results from the rest of the library or fail import.
- Capability flags describe integrated Kola features, not underlying engine primitives.
- Flow/selection/annotations must resolve back to stable source locations before being enabled.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #5 code head `bfde404261e1c04a037c43ee6ac0755f082ba9ec` passed Flutter CI run 101 on 2026-09-12 with Flutter 3.47.4 / Dart 3.13.3: dependency resolution, Drift generation, formatting, analyzer, FTS5 persistence/query/cleanup tests, lazy-index + revision-invalidation tests, and the full existing test suite are green. A final exact-head CI run is required after this mandatory state-file synchronization before merge.

## Current risks / blockers

- First query for an older/stale PDF can take time; new imports are warmed in the background but dedicated indexing-progress UX can improve later.
- PDF text order is extracted order, not yet validated semantic reading order.
- Scanned/image-only PDFs yield little/no text until local OCR exists.
- Physical PDF search/index/navigation still needs hands-on platform testing; CI validates code/data behavior, not full device UX.
- Native PDFium extraction tests require `PDFIUM_PATH` under `flutter test`.
- Text selection and durable text anchors are not implemented yet.

## Next recommended action

1. Merge verified persistent local search after exact-head CI.
2. Build source-linked PDF text selection from character indices + PDF rectangles.
3. Persist highlight/note anchors with quote/context + logical ranges + source geometry.
4. Render/search annotation results and only then enable PDF text-annotation capability.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests exist.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
