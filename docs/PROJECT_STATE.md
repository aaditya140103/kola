# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 0 implementation has started.**

The Flutter application foundation now exists in source form: package metadata, Riverpod root, go_router navigation, adaptive shell, tokenized theme system, initial Library/Home/Search/Insights/Reader prototypes, CI, smoke test, and native-platform bootstrap script.

Native Android/iOS/Linux/macOS/Windows project folders are intentionally generated with `bash tool/bootstrap.sh` on a Flutter-equipped machine rather than hand-maintained before the first real toolchain run.

## Current product state

- Product: local-first universal document reader + annotation workspace.
- Strategic wedge: beautiful universal reader + source-linked Flow Mode + best-in-class annotations + local-first/BYOC ownership + universal local search + Reading Intelligence + migration/interoperability.
- Product scope excludes AI assistants/LLMs and dedicated study systems.
- Targets: Linux, Windows, macOS, Android, iOS, tablets, foldables.
- Primary app stack: Flutter/Dart.
- State: Riverpod.
- Routing: go_router.
- Persistence direction: SQLite + Drift; package dependencies added, schema not implemented yet.
- Search direction: local FTS/indexing only; current Search screen is a prototype shell.
- Current UI: tokenized Kola Core prototype skin; final visual direction remains unvalidated.
- Current Reader: Flow/Fidelity shell only; no document engine attached yet.
- CI: GitHub Actions runs dependency resolution, formatting check, analysis, and tests.

## Implemented files

```text
pubspec.yaml
analysis_options.yaml
lib/main.dart
lib/app/kola_app.dart
lib/app/router.dart
lib/design_system/tokens/kola_tokens.dart
lib/design_system/theme/kola_theme.dart
lib/shared/widgets/kola_adaptive_scaffold.dart
lib/features/home/presentation/home_screen.dart
lib/features/library/presentation/library_screen.dart
lib/features/search/presentation/search_screen.dart
lib/features/insights/presentation/insights_screen.dart
lib/features/reader/presentation/reader_screen.dart
test/app_smoke_test.dart
tool/bootstrap.sh
.github/workflows/flutter-ci.yml
```

## Current UI behavior

- Compact widths use bottom navigation.
- Wider windows use NavigationRail; large widths extend labels.
- Home includes Continue Reading, Next Up, progress/coverage/time concepts, and weekly insight cards.
- Library uses a responsive book grid.
- Search communicates the local-search architecture and has prototype results.
- Insights has responsive metrics and a simple weekly reading chart.
- Reader is immersive, hides/reveals chrome, switches between Flow/Fidelity prototypes, and exposes progress/annotation/navigation controls.
- App light/dark theme follows system theme; reader-surface styling remains separately evolvable.

## Key invariants

- Local reading requires no network.
- Cloud sync is optional user-controlled transport.
- Never sync the live SQLite database file.
- One Flutter codebase.
- Universal format adapters; no PDF-only product architecture.
- Flow Mode is universal and source-linked.
- Annotation anchors are source-based/hybrid.
- Position progress, reading coverage, and active reading time are distinct.
- Reading List is separate from Favorites.
- AI and dedicated study systems remain out of scope.
- Visual style is not locked; shared UI stays tokenized.
- User data is durable; caches/derived aggregates are rebuildable.

## Most recent context change

Started the actual codebase:

- added current foundational packages (`flutter_riverpod`, `go_router`, `drift`, `sqlite3`, `path_provider`);
- added Kola spacing/radius/motion/breakpoint/color tokens;
- added system light/dark application themes;
- added adaptive navigation shell;
- added Home, Library, Search, Reading Insights, and Reader prototypes;
- added Flow/Fidelity prototype switching and immersive reader chrome;
- added smoke test and Flutter CI;
- added `tool/bootstrap.sh` to generate native platform projects and run checks;
- expanded `.gitignore` for Flutter artifacts;
- updated README with development/bootstrap instructions.

## Risks / blockers

- This execution environment does not contain Flutter/Dart, so local compilation could not be performed here; GitHub CI is the current verification path.
- CI may expose Flutter-version/API issues in the first prototype and should be fixed before adding more features.
- Native platform project folders still need first generation through the bootstrap script.
- Drift schema and database lifecycle are not implemented yet.
- Universal Flow Mode, annotation anchoring, and real text selection remain the highest-risk core engineering areas.
- Current UI uses demo data only and must not leak prototype models into domain/storage layers.
- Final visual direction still requires comparative UX validation.

## Next recommended action

1. Inspect/fix the first Flutter CI run until formatting, analysis, and tests are green.
2. Generate native platform folders with `bash tool/bootstrap.sh` on a Flutter-equipped machine and commit stable generated platform scaffolding.
3. Add `PlatformProfile` / input-capability abstractions and reduced-motion handling.
4. Implement the first Drift database schema for documents, reading state, sessions, planned reading items, goals, and annotations.
5. Replace Home/Library demo records with repository-backed local data.
6. Define `DocumentAdapter`, `FormatRegistry`, KDG node/source-map interfaces.
7. Integrate PDF fidelity reading only after those app-owned interfaces exist.
8. Keep visual primitives tokenized until the UX comparison is run.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

If architecture changes, also update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. If feature scope changes, update `FEATURE_STRATEGY.md`. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
