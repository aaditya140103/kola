# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: first real PDF Fidelity View.**

Kola can import local documents into a stable content-addressed library and now has its first concrete format engine: PDF via `pdfrx`/PDFium. Reader resolves a persisted document by ID, chooses app-owned capabilities/renderers, and renders real local PDF pages. PDF Flow/search/selection/annotations are intentionally not enabled yet.

## Current implementation

- App: Flutter/Dart + Riverpod + go_router; declared Dart floor is 3.13.
- Persistence: SQLite/Drift schema v1 with reactive repository implementations.
- Import: native picker -> format probe + streamed SHA-256 -> managed copy or linked source -> repository.
- Identity: stable `sha256:<hex>` document ID (D-020).
- Timestamps: UTC ISO-8601 text at raw SQLite write boundaries (D-019).
- Source access: one app-owned `DocumentSourceResolver` handles managed and linked files.
- Registry: `FormatRegistry` contains `PdfrxPdfAdapter` for PDF.
- Fidelity UI: separate `FidelityRendererRegistry`; generic Reader never imports `pdfrx`.
- PDF: `pdfrx ^2.6.1`, progressive page loading, previous/next page navigation, zoom, keyboard navigation.
- Capabilities: PDF currently advertises **fidelity only**. Flow, text selection, search, text annotations, outline UI, and export remain false/unintegrated.
- Reader: title/format come from the persisted `KolaDocument`; fake prototype document text has been removed.
- UI: tokenized Kola Core prototype; final visual direction remains unvalidated.

## Core reader path

```text
Library item/documentId
  -> DocumentRepository
  -> KolaDocument
  -> FormatRegistry -> DocumentAdapter capabilities/lifecycle
  -> FidelityRendererRegistry
  -> DocumentSourceResolver
  -> pdfrx PdfViewer.file
  -> real PDF pages + page/zoom controls
```

The adapter opens a `KolaDocument`, not a bare path/source, so `DocumentHandle.documentId` always preserves stable Kola identity.

## Important files

```text
lib/core/providers/document_engine_providers.dart
lib/document/source/document_source_resolver.dart
lib/document/registry/document_adapter.dart
lib/document/fidelity/document_fidelity_renderer.dart
lib/document/adapters/pdf/pdfrx_pdf_adapter.dart
lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart
lib/features/reader/presentation/reader_screen.dart
lib/core/providers/app_data_providers.dart
lib/main.dart
pubspec.yaml
test/document/source/document_source_resolver_test.dart
test/document/registry/pdf_registration_test.dart
```

## Invariants

- Core reading requires no network or account.
- Original source files are never modified.
- Managed source copies are durable user-library files, not cache.
- Format packages do not escape Kola-owned registries/contracts into generic feature code.
- Capability flags describe **integrated Kola behavior**, not merely what a third-party engine can theoretically do.
- Flow Mode must be source-linked before it can be enabled.
- Text selection/annotations must not be enabled until PDF coordinates/ranges can produce stable Kola anchors.
- Position, reading coverage, and active reading time remain distinct.
- AI and dedicated study systems remain out of scope.
- BYOC stays optional and outside the critical reading path.

## Verification

Import/persistence milestone is merged on `main` and previously passed full Flutter CI. PR #2 validates the PDF fidelity milestone. Added tests cover managed/linked/missing source resolution and ensure the PDF adapter does not claim unfinished Flow/search/selection/annotation capabilities.

## Current risks / blockers

- Real PDF rendering still needs hands-on Linux/Android/iOS/Windows/macOS device testing after CI compilation succeeds.
- Password-protected/corrupt PDF UX is not yet Kola-specific.
- PDF current-page/zoom state is not persisted into `reading_states` yet.
- PDF text extraction, source-coordinate mapping, selection, search, annotations, and Flow remain unimplemented.
- Native platform project folders still need stable generation/commit using `bash tool/bootstrap.sh` on a Flutter-equipped development machine.
- Schema v1 has no release migration path yet because no released schema exists.

## Next recommended action

1. Make PR #2 pass CI and merge it.
2. Persist PDF page/zoom position into `ReadingState` and restore it on reopen.
3. Extract PDF page text and geometry through pdfrx/PDFium into Kola-owned source locations.
4. Build local PDF search/index chunks from that extraction.
5. Add source-linked PDF text selection and durable highlight/note anchors.
6. Only then enable PDF text-selection/search/annotation capability flags.
7. Begin reconstructed PDF Flow Mode after reading-order/source-map quality tests exist.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable choices -> `DECISIONS.md`. Feature-scope changes -> relevant detailed spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
