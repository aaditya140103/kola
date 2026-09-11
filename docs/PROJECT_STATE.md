# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 0 now includes a verified UI shell plus the first durable domain/persistence foundation.**

Kola has a working Flutter foundation, adaptive prototype UI, Kola-owned document/reading/annotation contracts, KDG primitives, a universal `DocumentAdapter` interface, and Drift schema v1. GitHub CI verifies dependency resolution, Drift code generation, analyzer, database tests, and the application smoke test on Flutter 3.47.4 / Dart 3.13.3.

Native Android/iOS/Linux/macOS/Windows project folders are still generated with `bash tool/bootstrap.sh` on a Flutter-equipped development machine.

## Current product/implementation state

- Product: local-first universal document reader + annotation workspace.
- Targets: Linux, Windows, macOS, Android, iOS, tablets, foldables.
- App: Flutter/Dart + Riverpod + go_router.
- Persistence: SQLite/Drift schema v1 implemented and code-generated at build time.
- Timestamp storage: ISO-8601 text from schema v1 (D-019).
- Search: local FTS/indexing direction only; UI remains prototype.
- UI: tokenized Kola Core prototype; final visual direction remains unvalidated.
- Reader: Flow/Fidelity shell only; no real format renderer attached yet.
- Domain: Kola-owned document models, KDG nodes/chunks, reading models, annotations, repository contracts.
- Format boundary: universal `DocumentAdapter` contract exists; `FormatRegistry` and actual adapters are not implemented yet.
- Verification: code generation + analyzer + tests are green in GitHub Actions.

## Implemented persistence/domain files

```text
build.yaml
lib/core/database/schema.drift
lib/core/database/kola_database.dart
lib/core/database/database_provider.dart
lib/document/model/document_models.dart
lib/document/graph/kola_document_graph.dart
lib/document/registry/document_adapter.dart
lib/features/library/domain/document_repository.dart
lib/features/progress/domain/reading_models.dart
lib/features/progress/domain/reading_repository.dart
lib/features/annotations/domain/annotation_models.dart
lib/features/annotations/domain/annotation_repository.dart
test/core/database/kola_database_test.dart
```

Generated `*.g.dart` files are build artifacts and are intentionally not committed.

## Database schema v1

Durable tables currently cover:

- documents
- reading_states
- reading_coverage
- reading_sessions
- planned_reading_items
- reading_goals
- annotations
- bookmarks

Foreign keys are enabled on open. Document deletion cascades dependent reading/annotation state where appropriate; the cascade behavior is tested.

## Existing UI foundation

- compact bottom navigation; larger windows use NavigationRail;
- Home with Continue Reading, Next Up, and weekly insight prototypes;
- responsive Library grid;
- Search and Reading Insights shells;
- immersive Reader shell with Flow/Fidelity switching;
- system light/dark app theme and tokenized reader styling.

## Key invariants

- Local reading requires no network.
- Cloud sync remains optional user-controlled transport.
- Never sync the live SQLite database file.
- One Flutter codebase.
- Format packages never escape through Kola domain contracts.
- Flow Mode remains universal and source-linked.
- Annotation anchors remain hybrid/source-based, never screen-coordinate-only.
- Position, coverage, and active reading time remain distinct.
- Reading List remains separate from Favorites.
- AI and dedicated study systems remain out of scope.
- Visual style is not locked; shared UI remains tokenized.
- User-generated data is durable; caches/generated code/derived aggregates are rebuildable.

## Most recent context change

Completed the domain + persistence foundation:

- added `drift_flutter`, `drift_dev`, and `build_runner` support;
- added Drift schema v1 and background/platform-appropriate database opening;
- added Riverpod database provider;
- added Kola document models and normalized KDG primitives;
- added universal `DocumentAdapter` and format-capability contract;
- added reading state/coverage/session/list/goal models;
- added annotation model with source-linked anchor contract;
- added document, reading, and annotation repository interfaces;
- configured ISO-8601 Drift datetime storage and recorded D-019;
- added database tests for persistence and foreign-key cascade behavior;
- CI now generates Drift sources before analyze/test;
- latest full CI run is green.

## Risks / blockers

- Native platform project folders still need first generation on a Flutter-equipped machine.
- Concrete Drift repository implementations/mappers do not exist yet; UI still uses demo records.
- Schema v1 has no upgrade migration yet because no released schema exists; migrations become mandatory at the first schema change after release/testing data matters.
- `FormatRegistry` detection/probing is not implemented.
- Universal Flow Mode, source-map quality, annotation resolution, and real text selection remain the highest-risk core engineering areas.
- Broad format adapters still require parser/license evaluation.
- Final visual direction still requires comparative UX validation.

## Next recommended action

1. Implement concrete Drift repositories and serialization/mapping for documents, reading state, sessions/list/goals, and annotations.
2. Expose those repositories through Riverpod and replace Home/Library/Insights demo models with repository-backed state.
3. Add `FormatRegistry`, `FormatMatch`, and capability-driven adapter registration/detection.
4. Add import/fingerprint plumbing for local files before attaching real renderers.
5. Integrate the first PDF fidelity adapter behind `DocumentAdapter` only after registry/import identity is stable.
6. Begin real source-linked annotation/text-selection work after PDF source locations are available.
7. Generate/commit stable native platform scaffolding with `bash tool/bootstrap.sh` on a Flutter-equipped machine.
8. Keep visual primitives tokenized until comparative UX validation is run.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

If architecture changes, also update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. If feature scope changes, update `FEATURE_STRATEGY.md`. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
