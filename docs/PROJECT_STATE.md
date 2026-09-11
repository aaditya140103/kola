# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Specification / architecture complete enough to begin Phase 0 implementation, with evidence-based UX methodology now defined.**

The repository contains product, architecture, universal-format, adaptive UX, scientific UX research/validation, optional BYOC sync, roadmap, agent-context, decision, and project-graph specifications. The Flutter application scaffold has not yet been initialized.

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
- `docs/UNIVERSAL_FORMATS.md` — format strategy.
- `docs/SYNC.md` — optional Bring Your Own Cloud sync protocol/architecture.
- `docs/ROADMAP.md` — implementation order.
- `docs/RESEARCH.md` — general research/reference material; do not read by default.

## Most recent context change

Added an evidence-based UI/UX framework because appearance and long-term reading comfort are core Kola product requirements:

- created `docs/UX_RESEARCH.md` with evidence tiers, aesthetics research, reading/typography rules, contrast, motion, platform trends, cognitive-accessibility principles, and Kola's visual thesis;
- created `docs/UX_VALIDATION.md` with a scientific design loop, task metrics, long-reading studies, longitudinal testing, accessibility gates, UEQ-S/SUS/VisAWI-S/NASA-TLX usage, and experiment templates;
- added the UX evidence loop to `PROJECT_GRAPH.md`;
- added durable decision D-015: UI/UX is evidence-driven, not trend-driven;
- updated `AGENTS.md` so meaningful visual changes require a stated rationale and appropriate validation;
- surfaced the UX research/validation documents from the README.

Agent-continuity rules remain mandatory: every patch updates this file, architecture changes update `PROJECT_GRAPH.md`, and durable decisions update `DECISIONS.md`.

## Risks / open engineering questions

- Exact libraries/engines for every ebook, Office, DjVu, archive, and legacy format must be validated during adapter implementation.
- Universal Flow Mode quality differs by source format; complex regions require source-preserving fallbacks.
- Annotation anchoring and text-selection correctness remain the highest-risk core engineering areas.
- Office fidelity rendering may require platform/native or conversion strategies that must remain local and license-compatible.
- Kola needs its own user-research baseline before numerical UX targets are treated as release thresholds.
- Visual expressiveness must be validated in long reading sessions; first-impression preference alone is insufficient.
- Cross-platform custom controls must preserve native accessibility, input, and reduced-motion behavior.
- Sync merge semantics need adversarial multi-device tests before provider integrations.

## Next recommended action

Initialize **Phase 0**:

1. Create Flutter project targeting all supported native platforms.
2. Establish `lib/app`, `lib/core`, `lib/design_system`, `lib/document`, and `lib/features` boundaries.
3. Add Riverpod, go_router, Drift/SQLite.
4. Implement adaptive-native application shell primitives.
5. Create design tokens for spacing, typography, color roles, geometry, motion, elevation/material, and breakpoints.
6. Implement separate app-theme and reader-theme models.
7. Build the first Library + empty Reader shell prototypes and evaluate hierarchy at compact/expanded widths against `UX_RESEARCH.md`.
8. Add stable UUID/revision fields to durable domain entities for future sync.
9. Add CI for formatting, analysis, tests, and later golden visual tests.

Do **not** implement cloud providers in Phase 0. Do not prematurely add fashionable glass/motion effects before the design-system primitives and prototype validation exist.

## Required update after every patch

Replace/update only the sections affected by the patch:

- `Current milestone`
- `Most recent context change`
- `Risks / open engineering questions`
- `Next recommended action`

If architecture changes, also update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. Meaningful UX changes must be checked against `UX_RESEARCH.md` and the validation approach in `UX_VALIDATION.md`. Keep this file concise and current rather than accumulating history.
