# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-13

## Current milestone

**Phase 2: PDF fidelity + search + source-linked annotation management/recovery.**

The stability/debug pass is merged on main (startup pdfrx init, import detection, per-highlight recovery isolation, search revision serialization, managed-copy repair). This patch resumes the deferred roadmap item: batch/multi-quote anchor recovery — one recovery pass now scans pages once for all pending quotes instead of once per distinct quote.

The repo also carries a **dev-only web preview harness** (`tool/web_preview/`): a static web mirror of the current Flutter UI served at `http://0.0.0.0:8080` because the development sandbox cannot run Flutter (network policy blocks `pub.dev` and Flutter's Google storage). It shares no code with the product.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + local FTS5.
- Managed/linked imports, streamed SHA-256 identity, real PDF fidelity and durable page/zoom resume.
- PDF source text/geometry, local search/source jumps, persistent highlights, notes/recolor/delete, conservative anchor recovery and transient recovered geometry.
- App startup awaits `pdfrxFlutterInitialize()` before mounting Kola, preventing direct PDF adapter work from racing pdfrx/PDFium initialization.
- Import detects the source before fingerprinting rather than leaving independent file-operation futures potentially unobserved after an early failure.
- Annotation geometry recovery is isolated per highlight: a thrown/corrupt anchor is skipped while other valid annotations continue to recover and render, in both sequential and batch paths.
- Search indexing serializes work per document revision. Newer revisions queue behind older work and stale callers cannot downgrade a newer persistent index.
- Managed-copy duplicate/reimport health requires both file existence and the expected byte length; wrong-sized managed files are recopied from the explicitly reselected matching source and remain one document identity. `LocalDocumentSourceStorage` replaces a wrong-sized destination through a temporary copy first.
- Batch anchor recovery: `AnnotationGeometryRecoveryService` uses the optional `BatchAnchorResolver` capability when present and resolves sequentially otherwise; `PdfrxPdfAdapter` warms its handle-scoped quote index with one Aho–Corasick pass over all pending unique quotes, then resolves each anchor through the unchanged per-anchor path.
- Measured: 50 distinct stale quotes × 200 pages fall from 10,000 per-anchor quote-scan page visits to one 200-page warm-up pass (0 per-anchor scans, 50 candidate cache hits, 0 misses; page-text extraction misses stay 200). The repeated-quote and no-index baselines are unchanged.
- Handle-scoped page-text and exact-quote caches remain disposable and local to one open PDF handle (D-029..D-032).
- Recovery profiling remains deterministic and operation-count based; it does not depend on machine-specific timing thresholds.
- Reader uses toolbar + Expanded source surface; Home/Library/Search push reader routes and Back restores origin with Library fallback for direct routes.
- PDF outline, lazy thumbnail navigation, Fit Width / Fit Page, and optional >= 840 dp facing-page spread remain integrated inside the PDF renderer boundary.
- PDF remains the only registered adapter/renderer. Import recognition does not imply reading support.

## Important files

- `lib/document/adapters/pdf/pdf_exact_quote_index.dart` (per-quote lookup + `warmUp` batch scan)
- `lib/document/registry/document_adapter.dart` (`BatchAnchorResolver` optional capability)
- `lib/features/annotations/application/annotation_geometry_recovery_service.dart`
- `lib/document/adapters/pdf/pdfrx_pdf_adapter.dart`
- `test/document/adapters/pdf/pdf_anchor_recovery_profile_test.dart`
- `test/features/annotations/annotation_geometry_recovery_service_test.dart`
- `lib/main.dart`, `lib/document/import/document_import_service.dart`, `lib/document/import/document_source_storage.dart`
- `lib/features/search/application/document_search_service.dart`
- `tool/web_preview/` (dev-only preview harness; see its README)
- `docs/PROJECT_GRAPH.md`

## Invariants

- Local reading/search/annotation requires no account/network; original files remain untouched.
- Generic reader code does not import pdfrx; PDF-engine behavior stays behind PDF boundaries.
- Readable source content must not be blocked by metadata, recovery, indexing, or annotation failures.
- Search index revisions must move forward for one document identity; stale callers cannot replace newer indexed state.
- Managed-copy repair only uses explicitly reselected matching content; it does not search arbitrary external files.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- A failed annotation recovery suppresses only that failed highlight, in batch and sequential paths.
- Exact-quote candidates remain advisory; every recovered candidate is still verified with current page text and context/ambiguity rules.
- Batch resolution returns the same resolutions, in input order, as sequential per-anchor resolution; a failed warm-up falls back to unchanged per-anchor scanning.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Page-text and quote caches remain disposable and handle-scoped; the warm-up automaton is transient per pass.
- Position progress stays separate from coverage and active reading time.
- No new format, cloud, AI or study-system scope is introduced.

## Verification

Stability commit `31f1333` passed Flutter CI #155; search-revision head `7dd0195` passed CI #158; managed-copy repair `cc67ffb` passed CI as well. Batch warm-up head `8b25e56` passed Flutter CI #161 (format report, analyzer, full test suite), including deterministic operation-count regressions: a 50-unique-quotes × 200-pages batch profile (one 200-page warm-up, 0 per-anchor quote-scan visits, 50 candidate cache hits), warm-up/per-quote scan candidate equivalence (including overlapping matches), failure eviction + retry, skip semantics, ambiguity/context invariants preserved after warm-up, per-anchor isolation in both paths, and service-level batch/sequential equivalence. Because the sandbox cannot run Dart, the algorithm and every new counter expectation were additionally validated against a faithful Python port of the cache/index/resolver logic before commit. Repository CI is the authoritative gate.

The preview harness touches no Dart code; it was verified headlessly in Chromium (43/43 DOM/pixel assertions) plus `node --check`. Flutter CI remains the only gate for product code.

## Risks / blockers

- Physical Linux/Android reproduction remains essential because CI cannot cover all native PDFium/window/file-picker timing and packaging behavior.
- Several PDF renderer actions are launched asynchronously from UI callbacks; controller/disposal races still require focused defensive handling.
- `Fit Page` reads the pdfrx page-layout list without a transient-layout bounds guard; rapid resize/spread changes can race this access.
- Flow-mode persistence has an unawaited save path that should be hardened before Flow becomes enabled for any format.
- Managed-copy health catches missing/truncated/wrong-sized files, but same-size bit corruption is not rehashed during ordinary duplicate import.
- Batch warm-up is scoped to one recovery pass over an open handle: single-annotation navigation still resolves one anchor per open handle, and the transient automaton costs O(total pending quote characters) memory per pass.
- Physical predictive Back, large text, keyboard focus, atypical/rotated/password PDFs, very large thumbnails/outlines, and packaging remain validation gaps.

## Next recommended action

1. Harden PDF renderer controller actions, transient page-layout access, selection callbacks, and reader persistence futures; add regressions where feasible.
2. Physically run import/open/scroll/select/search/annotations/Contents/Pages/Fit/Spread/Back/reopen on Linux, then Android, including 50+ stale annotations across a large PDF to exercise batch recovery in practice.
3. Capture any Fedora runtime stack traces that remain after the stability fixes and map them to the audited paths.
4. Consider profiling whether navigation (single-anchor) paths ever need warm-up sharing; do not add caches beyond the open handle.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
