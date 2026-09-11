# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 0 implementation is underway and the first application slice is verified.**

Kola now has a compilable/analyzable Flutter foundation with Riverpod, go_router, adaptive navigation, design tokens/themes, Home/Library/Search/Insights/Reader prototypes, a smoke test, CI, and a native-platform bootstrap script.

GitHub CI has verified the current foundation on **Flutter 3.47.4 / Dart 3.13.3**: dependency resolution succeeds, `flutter analyze` reports no issues, and the application smoke test passes.

Native Android/iOS/Linux/macOS/Windows project folders are generated with `bash tool/bootstrap.sh` on a Flutter-equipped development machine.

## Current product state

- Product: local-first universal document reader + annotation workspace.
- Strategic wedge: beautiful universal reader + source-linked Flow Mode + best-in-class annotations + local-first/BYOC ownership + universal local search + Reading Intelligence + migration/interoperability.
- Product scope excludes AI assistants/LLMs and dedicated study systems.
- Targets: Linux, Windows, macOS, Android, iOS, tablets, foldables.
- Primary app stack: Flutter/Dart.
- State: Riverpod.
- Routing: go_router.
- Persistence direction: SQLite + Drift; dependencies exist, schema not implemented yet.
- Search direction: local FTS/indexing only; current Search screen is a prototype shell.
- Current UI: tokenized Kola Core prototype skin; final visual direction remains unvalidated.
- Current Reader: Flow/Fidelity shell only; no document engine attached yet.
- Verification: analyzer + smoke test green in GitHub Actions.

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
- Continue Reading sizing is content-driven to avoid constrained-height overflow.
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

Completed the first verification/fix cycle:

- CI resolved the Phase 0 dependencies on Flutter 3.47.4 / Dart 3.13.3;
- fixed missing Cupertino transition and sliver-layout imports exposed by the analyzer;
- fixed a current Dart lint issue in the Home prototype;
- `flutter analyze` is now green;
- the smoke test exposed a real compact-layout overflow in Continue Reading;
- replaced the fixed-height Continue Reading layout with content-driven sizing;
- made the app-bar smoke assertion resilient to `SliverAppBar.large` internal duplicate title widgets;
- `flutter test` is now green;
- CI now cancels superseded runs so rapid commits do not waste multiple full Flutter setup jobs.

## Risks / blockers

- This execution environment itself does not contain Flutter/Dart; GitHub Actions is the verified toolchain path here.
- Native platform project folders still need generation on a Flutter-equipped development machine.
- CI currently reports formatting but does not enforce it; restore a strict format gate after the initial source is run through `dart format` on a developer machine.
- Drift schema and database lifecycle are not implemented yet.
- Universal Flow Mode, annotation anchoring, and real text selection remain the highest-risk core engineering areas.
- Current UI uses demo data only and must not leak prototype models into domain/storage layers.
- Final visual direction still requires comparative UX validation.

## Next recommended action

1. Generate and commit stable native platform scaffolding with `bash tool/bootstrap.sh` on a Flutter-equipped machine.
2. Add `PlatformProfile` / input-capability abstractions and reduced-motion handling.
3. Implement the first Drift database schema for documents, reading state, reading sessions, planned reading items, goals, and annotations.
4. Introduce repository interfaces so Home/Library stop depending on demo records.
5. Define `DocumentAdapter`, `FormatRegistry`, KDG node/source-map interfaces.
6. Integrate PDF fidelity reading only after those app-owned interfaces exist.
7. Restore strict formatting CI after a developer-machine `dart format lib test` pass.
8. Keep visual primitives tokenized until the UX comparison is run.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

If architecture changes, also update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. If feature scope changes, update `FEATURE_STRATEGY.md`. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
