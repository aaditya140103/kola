# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 1: real local document ingestion and stable document identity.**

Kola now has the adaptive Flutter shell, reactive Drift repositories, live Home/Library/Insights data, universal document contracts, `FormatRegistry`, content-based format detection, streamed SHA-256 fingerprints, managed/linked source handling, and a native file-picker import path. No real renderer/parser adapter is registered yet.

Native Android/iOS/Linux/macOS/Windows project folders are still generated with `bash tool/bootstrap.sh` on a Flutter-equipped development machine.

## Current product/implementation state

- Product: local-first universal document reader + annotation workspace.
- Targets: Linux, Windows, macOS, Android, iOS, tablets, foldables.
- App: Flutter/Dart + Riverpod + go_router.
- Persistence: SQLite/Drift schema v1 with concrete reactive repositories.
- UI data path: Drift repositories -> Kola domain models -> Riverpod -> Home/Library/Insights.
- Import: native `file_picker` -> format detection + SHA-256 -> managed copy/linked source -> repository.
- Identity: stable `sha256:<hex>` full-file content fingerprint (D-020).
- Normal Import mode: managed byte-for-byte local copy in application-support storage (D-020).
- Format detection: signature + ZIP/container structure + extension evidence; probing runs off UI isolate.
- Registry: `FormatRegistry` exists; no concrete `DocumentAdapter` is registered yet.
- Reader: Flow/Fidelity shell only; no real format renderer attached yet.
- Search: local FTS/indexing direction only; UI remains prototype.
- Timestamp storage: raw repository writes normalize `DateTime` values to UTC ISO-8601 text before SQLite binding (D-019).
- UI: tokenized Kola Core prototype; final visual direction remains unvalidated.

## Implemented data/import foundation

```text
lib/core/database/schema.drift
lib/core/database/kola_database.dart
lib/core/providers/repository_providers.dart
lib/core/providers/app_data_providers.dart
lib/core/providers/import_providers.dart
lib/document/model/document_models.dart
lib/document/graph/kola_document_graph.dart
lib/document/registry/document_adapter.dart
lib/document/registry/format_match.dart
lib/document/registry/format_registry.dart
lib/document/import/document_file_picker.dart
lib/document/import/document_fingerprint_service.dart
lib/document/import/document_format_detector.dart
lib/document/import/document_source_storage.dart
lib/document/import/document_import_service.dart
lib/features/library/data/drift_document_repository.dart
lib/features/progress/data/drift_reading_repository.dart
lib/features/annotations/data/drift_annotation_repository.dart
```

Generated `*.g.dart` files remain build artifacts and are not committed.

## Import pipeline

```text
Native picker
  -> selected local path
  -> [parallel] SHA-256 fingerprint + format probe
  -> stable content identity
  -> managed copy (default) OR linked source
  -> FormatRegistry lookup
  -> adapter metadata if available / filename fallback otherwise
  -> DocumentRepository
  -> SQLite
  -> reactive Library/Home update
```

Rules:

- original source files are never modified;
- identical bytes do not create duplicate identities;
- moved/renamed identical content relinks the existing record;
- unknown files are rejected before library mutation;
- recognized formats without an adapter persist as `partial`, never as fake full support;
- managed copies are durable user-library files, not disposable cache data.

## Database schema v1

Durable tables: documents, reading_states, reading_coverage, reading_sessions, planned_reading_items, reading_goals, annotations, bookmarks. Foreign keys are enabled; document deletion cascades dependent state where appropriate.

## Existing UI foundation

- compact bottom navigation; larger windows use NavigationRail;
- Home with live Continue Reading, Next Up, and weekly insight data;
- responsive live Library grid;
- Home/Library Import actions invoke the native picker;
- Search and Reading Insights shells;
- immersive Reader shell with Flow/Fidelity switching;
- system light/dark app theme and tokenized reader styling.

## Key invariants

- Local reading requires no network.
- Cloud sync remains optional user-controlled transport.
- Never sync the live SQLite database file.
- One Flutter codebase.
- Format packages never escape Kola domain contracts.
- Flow Mode remains universal and source-linked.
- Annotation anchors remain hybrid/source-based, never screen-coordinate-only.
- Position, coverage, and active reading time remain distinct.
- Reading List remains separate from Favorites.
- AI and dedicated study systems remain out of scope.
- User-generated data and managed source copies are durable; caches/generated code/derived aggregates are rebuildable.

## Verification coverage

The import branch passed full Flutter CI on 2026-09-12: dependency resolution, Drift generation, formatter, analyzer, and all tests. Tests cover database cascade behavior, repository round-trips/reactivity, ISO timestamp writes, app-shell rendering, content-format detection, stable import identity, idempotent re-import, moved-source relinking, and unknown-format rejection.

## Risks / blockers

- No real `DocumentAdapter` exists yet, so imported recognized documents are library records with `partial` support.
- Native platform project folders still need stable generation/commit on a Flutter-equipped machine.
- File-provider/sandbox edge cases must be exercised on real Android/iOS devices even though normal import creates a managed copy.
- Legacy/proprietary format detection still needs deeper probes as adapters arrive.
- Schema v1 has no upgrade migration yet because no released schema exists.
- Universal Flow Mode, source-map quality, annotation resolution, and real text selection remain the highest-risk core engineering areas.

## Next recommended action

1. Implement the first PDF fidelity adapter behind `DocumentAdapter` and register it in `FormatRegistry`.
2. Resolve a document's readable managed/linked path through one app-owned helper rather than adapter-specific path logic.
3. Make Reader load a real imported PDF through document ID -> repository -> registry -> adapter.
4. Add PDF page navigation/zoom before text selection or annotation rendering.
5. Then add source-linked PDF text selection and annotation anchors.
6. Generate/commit stable native platform scaffolding with `bash tool/bootstrap.sh` on a Flutter-equipped machine.
7. Keep visual primitives tokenized until comparative UX validation is run.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

If architecture changes, also update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. If feature scope changes, update the relevant detailed spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
