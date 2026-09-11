# Kola — Decision Ledger

Short record of settled decisions. Update only when a durable product/technical choice changes.

## D-001 — Flutter is the primary application layer

- Status: accepted
- Decision: Use one Flutter/Dart codebase for Linux, Windows, macOS, Android, and iOS.
- Why: one product codebase with strong custom rendering and adaptive UI.

## D-002 — Kola is local-first

- Status: accepted
- Decision: Core reading, annotation, indexing, progress, and library features work without accounts or network access.
- Consequence: cloud services may never become required for basic reading.

## D-003 — Universal adapter architecture

- Status: accepted
- Decision: Every document format is accessed through an app-owned `DocumentAdapter` contract.
- Consequence: feature code must not depend directly on PDF/EPUB/package-specific types.

## D-004 — One normalized document graph

- Status: accepted
- Decision: Search, Flow Mode, annotations, structure, and progress operate on Kola-owned normalized document structures plus source maps.

## D-005 — Flow Mode is universal

- Status: accepted
- Decision: Flow Mode is a source-linked projection of normalized content, not a PDF-only feature.
- Consequence: unsupported complex regions remain source-preserving visual blocks.

## D-006 — Hybrid source-linked annotation anchors

- Status: accepted
- Decision: Combine structural locator, quote/context, offsets, and source geometry where available.
- Consequence: never rely only on screen coordinates.

## D-007 — SQLite + Drift for durable local app data

- Status: accepted
- Decision: Documents metadata, annotations, progress, collections, tags, and settings live in SQLite through Drift.
- Consequence: caches remain separate and disposable.

## D-008 — Adaptive-native UX

- Status: accepted
- Decision: Keep Kola semantics consistent while adapting navigation, chrome, menus, sheets, density, input behavior, and motion to platform/window/input.
- Consequence: do not scale one identical UI across all devices.

## D-009 — Window capability beats device labels

- Status: accepted
- Decision: Layout derives from available space and input capabilities, not simplistic phone/tablet/desktop checks.

## D-010 — Progress and coverage are separate

- Status: accepted
- Decision: Track current document position independently from actual reading coverage.

## D-011 — App and reader themes are separate

- Status: accepted
- Decision: Application chrome theme and document/reading theme/background can differ.

## D-012 — Rust is deferred

- Status: accepted
- Decision: Do not add a Rust/FFI core until profiling or missing capabilities justify it.

## D-013 — Context files are mandatory maintenance

- Status: accepted
- Decision: Every agent patch updates `docs/PROJECT_STATE.md`; architecture/data-flow changes update `docs/PROJECT_GRAPH.md`; durable choices update this file.
- Why: preserve continuity across agents while minimizing repeated context loading.

## D-014 — Bring Your Own Cloud, never mandatory Kola cloud

- Status: accepted
- Decision: Kola may synchronize across devices through a user-selected `SyncBackend` such as local folder, WebDAV, Google Drive, OneDrive, Dropbox, or S3-compatible storage.
- Consequences:
  - local reading remains complete without sync;
  - Kola never requires a Kola-hosted cloud account;
  - the live SQLite database is never synchronized as a file;
  - sync uses versioned portable records plus a local merge engine;
  - users choose state-only, selected-document, or full-library sync;
  - network/sync failures never block local reading or annotation;
  - optional client-side encrypted sync vaults are part of the privacy direction.
- Detailed design: `docs/SYNC.md`.

## D-015 — UI/UX is evidence-driven, not trend-driven

- Status: accepted
- Decision: Kola treats visual design as a core product capability, but meaningful UI/interaction decisions must be grounded in accessibility/standards, human-factors evidence, native platform convention, measured Kola user results, or an explicitly documented experiment.
- Visual thesis: **calm reading surfaces + familiar structure + high craftsmanship + selective expressive interactions + native platform behavior**.
- Consequences:
  - first-impression appeal and long-session usability are both design goals;
  - the document remains visually dominant in the reader;
  - visual complexity is kept low while controlled diversity prevents sterile minimalism;
  - expressive color/motion is concentrated around interaction moments rather than long-form reading content;
  - platform-native behavior outranks superficial screenshot consistency;
  - accessibility and readability cannot be traded away for fashionable effects;
  - important UX changes should be validated using behavioral metrics plus validated subjective UX/aesthetic measures where appropriate.
- Evidence base: `docs/UX_RESEARCH.md`.
- Validation protocol: `docs/UX_VALIDATION.md`.
