# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Specification / architecture complete enough to begin Phase 0 implementation.**

The repository contains product, architecture, universal-format, adaptive UX, optional BYOC sync, roadmap, research, agent-context, decision, and project-graph specifications. The Flutter application scaffold has not yet been initialized.

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
- Initial sync families: local folder, WebDAV, Google Drive, OneDrive, Dropbox, S3-compatible.
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

See `docs/PROJECT_GRAPH.md` for diagrams and `docs/DECISIONS.md` for durable choices.

## Key invariants

- Local reading requires no network.
- Cloud sync is optional user-controlled transport.
- Never sync the live SQLite database file.
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
- `docs/PROJECT_GRAPH.md` — compact Mermaid architecture/workflow diagrams.
- `docs/DECISIONS.md` — settled decisions.
- `docs/APP.md` — full product requirements.
- `docs/ARCHITECTURE.md` — detailed document/local architecture.
- `docs/DESIGN_SYSTEM.md` — adaptive-native design system.
- `docs/UX_SPEC.md` — interaction/UI specification.
- `docs/UNIVERSAL_FORMATS.md` — format strategy.
- `docs/SYNC.md` — optional Bring Your Own Cloud sync protocol/architecture.
- `docs/ROADMAP.md` — implementation order.
- `docs/RESEARCH.md` — research/reference material; do not read by default.

## Most recent context change

Added optional **Bring Your Own Cloud** synchronization while preserving local-first operation:

- user-selected sync backends instead of mandatory Kola-hosted storage;
- state-only, selected-document, and full-library scopes;
- versioned portable sync records instead of copying SQLite;
- conflict-aware merge/tombstone model;
- content-addressed document blobs;
- optional client-side encrypted Sync Vault direction;
- dedicated `docs/SYNC.md` and sync graphs.

Agent-continuity rules remain mandatory: every patch updates this file, architecture changes update `PROJECT_GRAPH.md`, and durable decisions update `DECISIONS.md`.

## Risks / open engineering questions

- Exact libraries/engines for every ebook, Office, DjVu, archive, and legacy format must be validated during adapter implementation.
- Universal Flow Mode quality differs by source format; complex regions require source-preserving fallbacks.
- Annotation anchoring and text-selection correctness remain the highest-risk core engineering areas.
- Office fidelity rendering may require platform/native or conversion strategies that must remain local and license-compatible.
- Sync merge semantics need adversarial multi-device tests before provider integrations.
- OAuth/secure credential storage varies by platform and must remain behind platform/provider abstractions.
- Encrypted vault key recovery UX/security needs a dedicated design before release.

## Next recommended action

Initialize **Phase 0**:

1. Create Flutter project targeting all supported native platforms.
2. Establish `lib/app`, `lib/core`, `lib/design_system`, `lib/document`, and `lib/features` boundaries.
3. Add Riverpod, go_router, Drift/SQLite.
4. Implement adaptive-native application shell primitives.
5. Add theme tokens and separate app/reader theme models.
6. Add stable UUID/revision fields to durable domain entities so future sync does not require destructive migration.
7. Add CI for formatting, analysis, and tests.

Do **not** implement cloud providers in Phase 0. Build the local domain first, but keep entity identity and change tracking sync-ready.

## Required update after every patch

Replace/update only the sections affected by the patch:

- `Current milestone`
- `Most recent context change`
- `Risks / open engineering questions`
- `Next recommended action`

If architecture changes, also update `PROJECT_GRAPH.md`. If a durable decision changes, update `DECISIONS.md`. Keep this file concise and current rather than accumulating history.
