# Kola — Decision Ledger

Compact record of settled product/technical choices. Update only for durable decisions.

- **D-001 — Flutter application layer:** one Flutter/Dart codebase targets Linux, Windows, macOS, Android, and iOS.
- **D-002 — Local-first:** core reading, annotation, indexing, progress, and library behavior requires no account/network.
- **D-003 — Universal adapter architecture:** every format is accessed through Kola-owned `DocumentAdapter`; third-party parser types do not leak into generic feature/domain code.
- **D-004 — One normalized document graph:** Flow, search, annotations, structure, and progress operate on Kola-owned normalized structures + source maps.
- **D-005 — Universal Flow Mode:** Flow is a source-linked projection for all readable formats, not a PDF-only feature; unsafe regions remain source-preserving visual blocks.
- **D-006 — Hybrid annotation anchors:** combine source locator, quote/context, logical offsets, and geometry where available; never anchor only to screen coordinates.
- **D-007 — SQLite + Drift:** durable local metadata/progress/annotations/planning/settings live in SQLite through Drift; caches remain disposable.
- **D-008 — Adaptive-native UX:** Kola semantics stay stable while navigation/chrome/menus/sheets/input/motion adapt to platform/window/input.
- **D-009 — Capability-based layout:** use available space + input capability, not simplistic phone/tablet/desktop branches.
- **D-010 — Position != coverage:** current location and actually-read coverage are persisted separately.
- **D-011 — App theme != reader theme:** application chrome and document reading surface can use different themes/backgrounds.
- **D-012 — Rust deferred:** no Rust/FFI core until profiling or missing capabilities justify it.
- **D-013 — Context maintenance is mandatory:** every patch updates `PROJECT_STATE`; architecture changes update `PROJECT_GRAPH`; durable choices update this ledger.
- **D-014 — BYOC, never mandatory Kola cloud:** optional `SyncBackend` transports versioned portable records to user-controlled local folder/WebDAV/Drive/OneDrive/Dropbox/S3; never sync live SQLite; failures never block reading; optional client-side encryption is planned.
- **D-015 — Evidence-driven UX:** meaningful design changes require accessibility/standards, HCI evidence, native convention, measured Kola results, or explicit experiment. Visual thesis: calm reading surfaces + familiar structure + high craftsmanship + selective expression + native behavior.
- **D-016 — Private Reading Intelligence:** active reading time, sessions, history, Reading List/Next Up, goals/streaks, and analytics stay local by default; goals are optional/non-punitive; durable records may sync through BYOC.
- **D-017 — Focused reading product:** committed scope is beautiful universal reading + source-linked Flow + annotations + local-first/BYOC ownership + local search + Reading Intelligence + interoperability + read-aloud/lookup/compare.
- **D-018 — AI/study systems out of scope:** no BYO AI, document chat/summaries, semantic AI search, flashcards/SRS, knowledge graphs/backlinks, mind maps, Recall Mode, or quiz/study-sheet systems unless this decision is explicitly revisited.
- **D-019 — ISO-8601 timestamps:** Drift datetime values are stored as UTC ISO-8601 text; raw `customStatement` writes serialize `DateTime` before SQLite binding; changing storage mode requires migration.
- **D-020 — Content identity + managed import:** documents use streamed full-file `sha256:<hex>` identity; normal Import makes a durable byte-for-byte managed copy while linked/read-in-place remains explicit. Original files are untouched; identical bytes deduplicate; moved content retains identity; detection uses signatures + container structure + extension.
- **D-021 — First PDF engine is pdfrx/PDFium:** Kola uses `pdfrx ^2.6.1` for initial PDF fidelity rendering and requires Dart >=3.13 / Flutter >=3.47. Package-specific Flutter UI lives behind `FidelityRendererRegistry`; PDF document lifecycle/semantics live behind `DocumentAdapter`; generic Reader code must not import `pdfrx`. Capability flags expose only behavior integrated into Kola. Initial PDF capability is fidelity rendering only—Flow, search, text selection, text annotations, outline UI, and export stay disabled until source-linked integration exists. `DocumentAdapter.open()` receives a stable `KolaDocument`, not only a path/source, so handles preserve document identity across file moves/renames.
- **D-022 — Preserve source-native text geometry:** extraction adapters convert engine-specific text objects into Kola-owned `DocumentTextChunk` records. PDF character/fragment geometry remains in native PDF page coordinates (points, bottom-left origin) with page extent + rotation metadata; never persist zoom/window/screen coordinates as source geometry. `IndexChunk`s and future annotation anchors reference stable source locations/ranges. Extracted PDF text may enter KDG as conservative `sourceVisualBlock`s, but Flow/search/annotation capability flags remain disabled until their user-facing integrations are complete.
