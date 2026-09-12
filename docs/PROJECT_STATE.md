# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + resume + source text/geometry + persistent local search.**

Kola imports content-addressed local documents, renders real PDFs through `pdfrx`/PDFium, restores page/zoom state, extracts source-linked text/geometry, and now has an on-device persistent full-text search path. Text selection, annotations, and Flow remain intentionally disabled.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2; v2 adds app-owned FTS5 search tables/state + document-delete cleanup trigger.
- Import: native picker -> format probe + streamed SHA-256 -> managed copy or linked source.
- Stable identity: `sha256:<hex>` (D-020); timestamps use UTC ISO-8601 text (D-019).
- PDF engine: `pdfrx ^2.6.1` / PDFium behind `PdfrxPdfAdapter` (D-021).
- PDF fidelity: progressive rendering, page navigation, zoom, keyboard navigation, durable resume.
- PDF resume: source page + progress + zoom + view mode through `ReadingState`; saves debounce 400 ms and flush on exit.
- PDF extraction: `PdfPage.loadStructuredText()` -> `PdfTextGeometryMapper` -> Kola `DocumentTextChunk`.
- Geometry stays native PDF points with bottom-left origin (D-022).
- PDF `extractIndexableContent()` emits page-level `IndexChunk`s with stable PDF locators.
- `DriftSearchRepository` persists document metadata + content in SQLite FTS5 and stores index freshness separately.
- `DocumentSearchService` lazily indexes stale documents and reuses an index when document revision + extractor version match.
- Global Search now searches local metadata/content; Reader Search returns content hits only.
- Search results carry `DocumentLocation`; Reader converts them to format-neutral `FidelityNavigationRequest`s.
- PDF renderer resolves search jumps to exact source pages without exposing `PdfViewerController` outside the adapter renderer.
- PDF capability now advertises `fidelityView` + `textSearch`. Flow/text selection/text annotations remain false.

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
- Global search may include metadata; in-reader search must use content hits only.
- Search index failure for one document must not block results from the rest of the library.
- Capability flags describe integrated Kola features, not underlying engine primitives.
- Flow/selection/annotations must resolve back to stable source locations before being enabled.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #4 (PDF source text/geometry extraction) is merged and green. Current local-search branch adds FTS persistence tests, cleanup tests, lazy-index/revision invalidation tests, global Search UI, Reader Search UI, and format-neutral fidelity navigation. Full Flutter CI is required before merge.

## Current risks / blockers

- First query may take time because stale PDFs are indexed lazily; background indexing UX can be improved later.
- PDF text order is extracted order, not yet validated semantic reading order.
- Scanned/image-only PDFs yield little/no text until local OCR exists.
- FTS schema v2 is the first database migration; migration behavior must pass CI/in-memory tests before merge.
- Physical PDF search/index/navigation still needs hands-on platform testing.
- Native PDFium extraction tests require `PDFIUM_PATH` under `flutter test`.
- Text selection and durable text anchors are not implemented yet.

## Next recommended action

1. Pass CI and merge persistent local search.
2. Build source-linked PDF text selection from character indices + PDF rectangles.
3. Persist highlight/note anchors with quote/context + logical ranges + source geometry.
4. Render/search annotation results and only then enable PDF text-annotation capability.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests exist.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
