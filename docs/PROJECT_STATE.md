# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity View + durable resume state.**

Kola imports local documents into a content-addressed library and renders real PDFs via `pdfrx`/PDFium. PDF page/zoom/view-mode state now persists through the existing `reading_states` table. PDF Flow/search/selection/annotations remain intentionally disabled.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v1 with reactive repository implementations.
- Import: native picker -> format probe + streamed SHA-256 -> managed copy or linked source -> repository.
- Stable identity: `sha256:<hex>` (D-020).
- Raw SQLite timestamps: UTC ISO-8601 text (D-019).
- `DocumentSourceResolver` centralizes managed/linked source access.
- PDF engine: `pdfrx ^2.6.1` / PDFium behind `PdfrxPdfAdapter`.
- PDF fidelity UI lives behind `FidelityRendererRegistry`; generic Reader does not import `pdfrx`.
- PDF supports progressive rendering, page navigation, zoom, keyboard navigation, and durable resume state.
- `FidelityViewState` is format-neutral and carries source location + normalized position + zoom from renderer to Reader.
- Reader debounces page/zoom saves for 400 ms and flushes pending state on explicit exit/dispose.
- PDF source locator: `scheme=pdf`, `data.page=<1-based page>`.
- Restored state initializes PDF page, zoom, and saved view mode before presenting the reader.
- A stale-state overwrite race during immediate mode changes was removed by building the mode write from the exact state returned by the pending-position flush.
- PDF capability flags remain fidelity-only; search/Flow/text selection/annotation/export remain unintegrated.

## Resume data path

```text
pdfrx page/zoom event
  -> FidelityViewState
  -> Reader 400 ms debounce
  -> ReadingState
  -> ReadingRepository
  -> SQLite

reopen
  -> readingStateProvider
  -> FidelityViewState
  -> PdfrxPdfFidelityRenderer
  -> initial page + zoom
```

`position != coverage != active reading time`.

## Important files

```text
lib/document/fidelity/document_fidelity_renderer.dart
lib/document/adapters/pdf/pdf_fidelity_position.dart
lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart
lib/features/reader/presentation/reader_screen.dart
lib/features/progress/domain/reading_models.dart
lib/features/progress/data/drift_reading_repository.dart
test/document/adapters/pdf/pdf_fidelity_position_test.dart
test/core/repositories/repository_integration_test.dart
```

## Invariants

- Core reading requires no account/network.
- Original source files are never modified.
- Managed copies are durable user-library files, not cache.
- Format packages stay behind Kola-owned contracts/registries.
- Capability flags describe integrated Kola behavior, not theoretical package features.
- Flow must be source-linked before it can be enabled.
- Selection/annotations stay disabled until PDF text ranges/geometry can generate stable Kola anchors.
- Reading position, reading coverage, and active reading time stay separate.
- AI and dedicated study systems remain out of scope.
- BYOC remains optional and outside the critical reading path.

## Verification

Import/persistence and the first PDF fidelity reader are merged on `main`. PR #3 passed full Flutter CI on 2026-09-12 with Flutter 3.47.4 / Dart 3.13.3: dependency resolution, Drift generation, formatting, analyzer, and all tests are green. New coverage verifies PDF position encoding/restoration and a real SQLite round-trip for page locator, progress, view mode, and zoom.

## Current risks / blockers

- Physical PDF rendering/resume still needs hands-on Linux/Android/iOS/Windows/macOS testing; CI validates code/tests, not device UX.
- Password-protected/corrupt PDF UX is not yet Kola-specific.
- PDF resume is page-level; intra-page viewport offset is not persisted yet.
- PDF text extraction, geometry, search, selection, annotations, and Flow remain unimplemented.
- Native platform folders still need stable generation/commit with `bash tool/bootstrap.sh` on a Flutter-equipped machine.
- Schema v1 has no release migration path because no public schema release exists yet.

## Next recommended action

1. Merge verified PR #3.
2. Extract PDF page text + character/word geometry into Kola-owned source structures.
3. Produce local `IndexChunk`s and enable PDF search only after extraction tests pass.
4. Add source-linked PDF text selection and durable highlight/note anchors.
5. Enable annotation/search capability flags only after those integrations exist.
6. Begin reconstructed PDF Flow Mode after reading-order/source-map quality tests exist.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
