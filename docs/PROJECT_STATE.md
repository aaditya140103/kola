# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Specification / architecture complete enough to begin Phase 0 implementation.**

The repository currently contains product, architecture, format, UX, adaptive-design, roadmap, research, agent-context, and project-graph specifications. The Flutter application scaffold has not yet been initialized.

## Current product state

- Product: local-first universal document reader + annotation workspace.
- Targets: Linux, Windows, macOS, Android, iOS, tablets, foldables.
- Primary app stack: Flutter/Dart.
- Persistence: SQLite + Drift.
- State: Riverpod.
- Routing: go_router.
- Search: local FTS/indexing.
- PDF candidate: PDFium via adapter (`pdfrx` initially).
- Rust: deferred until measured need.

## Settled architecture

```text
Adaptive native shell
  -> Flutter application
  -> Kola domain/use cases
  -> DocumentAdapter registry
  -> format parsers/renderers
  -> NormalizedDocument + SourceMap
  -> Fidelity View / Flow Mode / Search / Annotation
  -> SQLite/Drift + local files
```

See `docs/PROJECT_GRAPH.md` for diagrams and `docs/DECISIONS.md` for durable choices.

## Key invariants

- Local reading requires no network.
- One Flutter codebase.
- Universal format adapters; no PDF-only product architecture.
- Flow Mode is universal and source-linked.
- Annotation anchors are source-based/hybrid.
- Kola semantics stay consistent; shell/interactions adapt natively.
- Position progress and reading coverage are separate.
- App theme and reader theme/background are separate.
- User data is durable; caches are disposable.

## Current documentation map

- `AGENTS.md` — canonical compact instructions for every coding agent.
- `docs/PROJECT_STATE.md` — this live state; update every patch.
- `docs/PROJECT_GRAPH.md` — compact Mermaid architecture and workflow diagrams.
- `docs/DECISIONS.md` — settled decisions.
- `docs/APP.md` — full product requirements.
- `docs/ARCHITECTURE.md` — detailed architecture/data model.
- `docs/DESIGN_SYSTEM.md` — adaptive-native design system.
- `docs/UX_SPEC.md` — interaction/UI specification.
- `docs/UNIVERSAL_FORMATS.md` — format strategy.
- `docs/ROADMAP.md` — implementation order.
- `docs/RESEARCH.md` — research/reference material; do not read by default.

## Most recent context change

Added an agent-continuity system designed to reduce repeated context loading:

- root `AGENTS.md` as canonical agent entrypoint;
- compact Mermaid `docs/PROJECT_GRAPH.md`;
- durable `docs/DECISIONS.md`;
- mandatory live `docs/PROJECT_STATE.md`;
- agent-specific files point to these sources instead of duplicating content.

## Risks / open engineering questions

- Exact libraries/engines for every ebook, Office, DjVu, archive, and legacy format must be validated during adapter implementation.
- Universal Flow Mode quality differs by source format; complex regions require source-preserving fallbacks.
- Annotation anchoring and text-selection correctness remain the highest-risk core engineering areas.
- Office fidelity rendering may require platform/native or conversion strategies that must remain local and license-compatible.

## Next recommended action

Initialize **Phase 0**:

1. Create Flutter project targeting all supported native platforms.
2. Establish `lib/app`, `lib/core`, `lib/design_system`, `lib/document`, and `lib/features` boundaries.
3. Add Riverpod, go_router, Drift/SQLite.
4. Implement adaptive-native application shell primitives.
5. Add theme tokens and separate app/reader theme models.
6. Add CI for formatting, analysis, and tests.

Do not begin broad format implementation before the shell/domain boundaries exist.

## Required update after every patch

Replace/update only the sections affected by the patch:

- `Current milestone`
- `Most recent context change`
- `Risks / open engineering questions`
- `Next recommended action`

If architecture changes, also update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. Keep this file concise and current rather than accumulating history.
