# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Specification / architecture complete enough to begin Phase 0 implementation; visual direction prototyping remains the immediate UX task. Product scope is now intentionally focused on reading/annotation and excludes AI and dedicated study systems.**

The repository contains product, focused feature-strategy, architecture, universal-format, adaptive UX, evidence-based UX research/validation, competing visual-direction, Reading Intelligence, optional BYOC sync, roadmap, agent-context, decision, and project-graph specifications. The Flutter application scaffold has not yet been initialized.

## Current product state

- Product: local-first universal document reader + annotation workspace.
- Strategic wedge: beautiful universal reader + source-linked Flow Mode + best-in-class annotations + local-first/BYOC ownership + universal local search + Reading Intelligence + migration/interoperability.
- Targets: Linux, Windows, macOS, Android, iOS, tablets, foldables.
- Primary app stack: Flutter/Dart.
- Persistence: SQLite + Drift.
- State: Riverpod.
- Routing: go_router.
- Search: local FTS/indexing.
- PDF candidate: PDFium via adapter (`pdfrx` initially).
- Sync: optional Bring Your Own Cloud through `SyncBackend` adapters; never required for reading.
- Reading Intelligence: active reading-time sessions, reading history, Reading List / Want to Read, Next Up queue, per-document insights, completion history, optional goals/streaks, local analytics.
- Supporting reader features: TTS/read-aloud, dictionary/lookup/translation, Parallel Read/Compare, import/export, Calibre/OPDS/KOReader interoperability where feasible.
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
  -> Progress + Coverage -> Reading Intelligence
  -> SQLite/Drift + local files
  -> optional Sync Projection -> user-selected SyncBackend
```

See `docs/PROJECT_GRAPH.md` for architecture + analytics + UX-process diagrams and `docs/DECISIONS.md` for durable choices.

## Key invariants

- Local reading requires no network.
- Cloud sync is optional user-controlled transport.
- Never sync the live SQLite database file.
- One Flutter codebase.
- Universal format adapters; no PDF-only product architecture.
- Flow Mode is universal and source-linked.
- Annotation anchors are source-based/hybrid.
- Position progress, reading coverage, and active reading time are distinct concepts.
- Reading time must not equal simple document-open duration.
- Reading List is separate from Favorites.
- Goals/streaks are optional and non-punitive.
- Reading analytics/history stay local unless explicitly included in BYOC sync.
- Kola semantics stay consistent; shell/interactions adapt natively.
- Meaningful UX choices require evidence, accessibility, platform convention, measured results, or explicit experimentation.
- Visual style is not locked yet; design primitives should remain tokenized enough to compare directions.
- New features must deepen the reading platform instead of creating disconnected silos.
- AI assistants/LLMs and dedicated study systems are explicitly out of scope unless the product decision is revisited.
- App theme and reader theme/background are separate.
- User data is durable; caches and precomputed analytics aggregates are disposable/rebuildable.

## Current documentation map

- `AGENTS.md` — canonical compact instructions for every coding agent.
- `README.md` — product overview and discovery entrypoint.
- `docs/PROJECT_STATE.md` — this live state; update every patch.
- `docs/PROJECT_GRAPH.md` — architecture, reading-intelligence, workflow, sync, and UX evidence-loop diagrams.
- `docs/DECISIONS.md` — settled decisions, including the explicit no-AI/no-study scope decision.
- `docs/APP.md` — full product requirements.
- `docs/FEATURE_STRATEGY.md` — focused S-tier reading feature strategy and explicit out-of-scope list.
- `docs/ARCHITECTURE.md` — detailed document/local architecture.
- `docs/DESIGN_SYSTEM.md` — adaptive-native design system.
- `docs/UX_SPEC.md` — interaction/UI specification.
- `docs/UX_RESEARCH.md` — scientific/HCI/accessibility/platform evidence behind visual rules.
- `docs/UX_VALIDATION.md` — hypothesis, prototype, testing, metrics, questionnaire, and release-gate protocol.
- `docs/VISUAL_DIRECTIONS.md` — competing visual systems, token roles, prototypes, and comparison criteria.
- `docs/READING_ANALYTICS.md` — active-time tracking, sessions, dashboard, reading history, Reading List, goals, completion analytics, and privacy.
- `docs/UNIVERSAL_FORMATS.md` — format strategy.
- `docs/SYNC.md` — optional Bring Your Own Cloud sync protocol/architecture.
- `docs/ROADMAP.md` — implementation order.
- `docs/RESEARCH.md` — general research/reference material; do not read by default.

## Most recent context change

Product scope was simplified after explicit product direction change:

- deleted `docs/AI.md`;
- removed BYO AI, local LLM, document-chat, AI-summary, and semantic-AI-search plans from the committed feature strategy;
- removed flashcards, SRS/spaced repetition, knowledge cards, backlinks/knowledge graph, mind maps, Recall Mode, study sheets, and quiz systems from the committed roadmap;
- rewrote `docs/FEATURE_STRATEGY.md` around S-tier reading features only;
- updated `AGENTS.md` so agents must not reintroduce AI or study systems without an explicit product-decision change;
- updated durable decisions with D-018 marking AI and dedicated study systems out of scope.

Agent-continuity rules remain mandatory: every patch updates this file, architecture changes update `PROJECT_GRAPH.md`, and durable decisions update `DECISIONS.md`.

## Risks / open engineering questions

- Universal Flow Mode remains the highest-risk differentiator because quality varies heavily by format/layout.
- Annotation anchoring and text-selection correctness remain core engineering risks.
- Broad format support requires careful adapter/library validation and license review.
- Migration/import formats and third-party interoperability APIs may change and need stable adapter boundaries.
- E-reader/KOReader integrations require careful identity, conflict, and statistics semantics.
- Active reading-time heuristics need real-user validation; static-page reading must not be mistaken for idle too quickly.
- Kola still needs actual prototypes/user data before one visual direction becomes the default.
- First-glance attractiveness may conflict with long-session reading comfort; both must be measured.

## Next recommended action

Start Phase 0 with a **prototype-first visual system and deliberately focused reader scope**:

1. Initialize the Flutter project and core design-token infrastructure.
2. Build tokenized Library and Reader shells without format-specific complexity.
3. Prototype Luminous Paper, Editorial Scholar, Soft Expressive, and Kola Core using the same component logic.
4. Include `Continue Reading`, `Next Up`, a minimal Reading Insight state, and basic library/search affordances in prototypes.
5. Produce desktop + phone Library/Reader states plus annotation and appearance states.
6. Run the first comparative UX evaluation using `UX_VALIDATION.md`.
7. Lock only the winning/shared primitives; keep reader themes customizable.
8. Add local database schema with stable UUID/revision fields for documents, annotations, reading sessions, planned reading items, goals, progress/coverage, and future sync.
9. Begin reader MVP with PDF/EPUB and annotation correctness before broadening format coverage.
10. Add CI for formatting, analysis, tests, and later golden visual tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems. Do not hard-code a final visual style before comparative prototypes exist.

## Required update after every patch

Replace/update only the sections affected by the patch:

- `Current milestone`
- `Most recent context change`
- `Risks / open engineering questions`
- `Next recommended action`

If architecture changes, update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. If feature scope/prioritization changes materially, update `FEATURE_STRATEGY.md`. Meaningful UX changes must be checked against `UX_RESEARCH.md`, `UX_VALIDATION.md`, and the active hypotheses in `VISUAL_DIRECTIONS.md`.
