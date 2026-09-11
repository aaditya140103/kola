# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Specification / architecture complete enough to begin Phase 0 implementation; visual direction prototyping is now the immediate UX task.**

The repository contains product, architecture, universal-format, adaptive UX, evidence-based UX research/validation, competing visual-direction, optional BYOC sync, roadmap, agent-context, decision, and project-graph specifications. The Flutter application scaffold has not yet been initialized.

## Current product state

- Product: local-first universal document reader + annotation workspace.
- Targets: Linux, Windows, macOS, Android, iOS, tablets, foldables.
- Primary app stack: Flutter/Dart.
- Persistence: SQLite + Drift.
- State: Riverpod.
- Routing: go_router.
- Search: local FTS/indexing.
- PDF candidate: PDFium via adapter (`pdfrx` initially).
- Sync: optional Bring Your Own Cloud through `SyncBackend` adapters; never required for reading.
- UX thesis: calm reading surfaces + familiar structure + high craftsmanship + selective expressive interactions + native platform behavior.
- Visual hypotheses: Luminous Paper, Editorial Scholar, Soft Expressive, and Kola Core hybrid candidate.
- UX process: evidence/accessibility/platform convention -> hypothesis/prototype -> behavioral + subjective validation.
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
  -> optional Sync Projection -> user-selected SyncBackend
```

See `docs/PROJECT_GRAPH.md` for architecture + UX-process diagrams and `docs/DECISIONS.md` for durable choices.

## Key invariants

- Local reading requires no network.
- Cloud sync is optional user-controlled transport.
- Never sync the live SQLite database file.
- One Flutter codebase.
- Universal format adapters; no PDF-only product architecture.
- Flow Mode is universal and source-linked.
- Annotation anchors are source-based/hybrid.
- Kola semantics stay consistent; shell/interactions adapt natively.
- Meaningful UX choices require evidence, accessibility, platform convention, measured results, or explicit experimentation.
- Visual style is not locked yet; design primitives should remain tokenized enough to compare directions.
- Position progress and reading coverage are separate.
- App theme and reader theme/background are separate.
- User data is durable; caches are disposable.

## Current documentation map

- `AGENTS.md` — canonical compact instructions for every coding agent.
- `README.md` — product overview and discovery entrypoint.
- `docs/PROJECT_STATE.md` — this live state; update every patch.
- `docs/PROJECT_GRAPH.md` — architecture, workflow, sync, and UX evidence-loop diagrams.
- `docs/DECISIONS.md` — settled decisions.
- `docs/APP.md` — full product requirements.
- `docs/ARCHITECTURE.md` — detailed document/local architecture.
- `docs/DESIGN_SYSTEM.md` — adaptive-native design system.
- `docs/UX_SPEC.md` — interaction/UI specification.
- `docs/UX_RESEARCH.md` — scientific/HCI/accessibility/platform evidence behind visual rules.
- `docs/UX_VALIDATION.md` — hypothesis, prototype, testing, metrics, questionnaire, and release-gate protocol.
- `docs/VISUAL_DIRECTIONS.md` — competing visual systems, token roles, prototypes, and comparison criteria.
- `docs/UNIVERSAL_FORMATS.md` — format strategy.
- `docs/SYNC.md` — optional Bring Your Own Cloud sync protocol/architecture.
- `docs/ROADMAP.md` — implementation order.
- `docs/RESEARCH.md` — general research/reference material; do not read by default.

## Most recent context change

Added the first concrete visual-design comparison system:

- created `docs/VISUAL_DIRECTIONS.md`;
- defined Luminous Paper, Editorial Scholar, Soft Expressive, and Kola Core hybrid candidate;
- defined semantic color/spacing/radius/depth/motion token roles;
- identified the components that establish Kola's identity;
- required desktop/mobile Library + Reader + annotation + appearance prototypes before style selection;
- defined comparative testing against aesthetics, task success, discoverability, reading comfort, platform familiarity, accessibility, and long-session preference;
- updated `AGENTS.md` and `README.md` so agents do not prematurely lock a visual style.

Agent-continuity rules remain mandatory: every patch updates this file, architecture changes update `PROJECT_GRAPH.md`, and durable decisions update `DECISIONS.md`.

## Risks / open engineering questions

- Kola needs actual prototypes/user data before one visual direction becomes the default.
- First-glance attractiveness may conflict with long-session reading comfort; both must be measured.
- Glass/transparency effects need contrast, battery/GPU, and platform-performance validation.
- Expressive color/motion must not create visual noise inside the reading surface.
- Exact libraries/engines for broad document formats still require implementation validation.
- Annotation anchoring and text-selection correctness remain core engineering risks.
- Sync merge semantics need adversarial multi-device tests before provider integrations.

## Next recommended action

Start Phase 0 with a **prototype-first visual system**:

1. Initialize the Flutter project and core design-token infrastructure.
2. Build tokenized Library and Reader shells without format-specific complexity.
3. Prototype Luminous Paper, Editorial Scholar, Soft Expressive, and Kola Core using the same component logic.
4. Produce desktop + phone Library/Reader states plus annotation and appearance states.
5. Run the first comparative UX evaluation using `UX_VALIDATION.md`.
6. Lock only the winning/shared primitives; keep reader themes customizable.
7. Then continue with local database, routing/state architecture, and first document adapter integration.

Do not implement cloud providers yet. Do not hard-code a final visual style before comparative prototypes exist.

## Required update after every patch

Replace/update only the sections affected by the patch:

- `Current milestone`
- `Most recent context change`
- `Risks / open engineering questions`
- `Next recommended action`

If architecture changes, update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. Meaningful UX changes must be checked against `UX_RESEARCH.md`, `UX_VALIDATION.md`, and the active hypotheses in `VISUAL_DIRECTIONS.md`.
