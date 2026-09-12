# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-13

## Current milestone

**Phase 2: PDF fidelity + search + source-linked annotation management/recovery; reader continuity and adaptive page layout.**

PDF reader continuity and adaptive page controls are merged. This patch adds handle-scoped batch/multi-quote anchor recovery: one recovery pass now collects exact-quote candidates for all pending highlight anchors with a single page-text scan (Aho–Corasick over the pending quotes) instead of one full-document scan per distinct quote, while per-anchor candidate verification, context scoring, and ambiguity rules are unchanged.

The repo also carries a **dev-only web preview harness** (`tool/web_preview/`): a static web mirror of the current Flutter UI (tokens, shell, Home/Library/Search/Insights, reader with real PDF rendering, selection highlights, annotation panel, in-document search, fit/spread/zoom, debounced position resume) served at `http://0.0.0.0:8080`. It exists because the development sandbox cannot run Flutter (network policy blocks `pub.dev` and Flutter's Google storage), and shares no code with the product.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + local FTS5.
- Managed/linked imports, streamed SHA-256 identity, real PDF fidelity and durable page/zoom resume.
- PDF source text/geometry, local search/source jumps, persistent highlights, notes/recolor/delete, conservative anchor recovery and transient recovered geometry.
- Handle-scoped page-text and exact-quote caches remain disposable and local to one open PDF handle (D-029..D-031).
- Recovery profiling is deterministic and operation-count based; it does not depend on machine-specific timing thresholds.
- Repeated-quote baseline: 50 stale annotations sharing one quote across 200 pages require 200 quote-scan page visits after candidate reuse, rather than 10,000 independent scans.
- Per-anchor unique-quote baseline (kept as the regression bound): 50 distinct stale quotes across 200 pages produce 10,000 quote-scan page visits and 50 exact-quote cache misses, while `PdfPageTextCache` still limits underlying page-text extraction misses to 200.
- New batch warm-up result: the same 50 distinct stale quotes need one 200-page warm-up pass (0 per-anchor quote-scan visits, 50 candidate cache hits, 0 misses; each anchor still loads its locator + candidate page from cache), meeting the roadmap target.
- `AnnotationGeometryRecoveryService` uses the optional `BatchAnchorResolver` capability when the adapter provides it and falls back to sequential `resolveAnchor` otherwise; `PdfrxPdfAdapter` implements the batch path by warming its handle-scoped quote index first.
- Reader uses toolbar + Expanded source surface; compact toolbar and PDF page controls wrap.
- Home/Library push reader routes, matching Search; Back restores origin with Library fallback for direct routes.
- PDF outline, lazy thumbnail navigation, Fit Width / Fit Page, and optional >= 840 dp facing-page spread remain integrated inside the PDF renderer boundary.
- Managed PDF fallback titles use the original source filename rather than the managed hash filename.
- Reader entry records `lastOpenedAt` once per reader instance without mutating structural revision/`updatedAt`.
- Missing managed copies can be repaired by reimporting matching bytes without creating a duplicate document identity.
- PDF remains the only registered adapter/renderer. Import recognition does not imply reading support.
- `tool/web_preview/` is a static web preview harness (pdf.js + generated sample books) mirroring the Flutter UI for browser review; dev tooling only, never part of the product or its verification.

## Important files

- `lib/document/adapters/pdf/pdf_anchor_recovery_profile.dart`
- `lib/document/adapters/pdf/pdf_anchor_resolver.dart`
- `lib/document/adapters/pdf/pdf_exact_quote_index.dart` (per-quote lookup + `warmUp` batch scan)
- `lib/document/adapters/pdf/pdf_page_text_cache.dart`
- `lib/document/registry/document_adapter.dart` (`BatchAnchorResolver` optional capability)
- `lib/features/annotations/application/annotation_geometry_recovery_service.dart`
- `test/document/adapters/pdf/pdf_anchor_recovery_profile_test.dart`
- `tool/web_preview/` (dev-only preview harness; see its README)
- `docs/PROJECT_GRAPH.md`

## Invariants

- Local reading/search/annotation requires no account/network; original files remain untouched.
- Generic reader code does not import pdfrx; PDF-engine behavior stays behind PDF boundaries.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- Exact-quote candidates remain advisory; every recovered candidate is still verified with current page text and context/ambiguity rules.
- Batch resolution must return the same resolutions, in input order, as sequential per-anchor resolution; a failed warm-up falls back to unchanged per-anchor scanning.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Page-text and quote caches remain disposable and handle-scoped.
- Profiling remains local/ephemeral and uses deterministic counters for CI assertions.
- Position progress stays separate from coverage and active reading time.
- No new format, cloud, AI or study-system scope is introduced.

## Verification

Continuity commit `c4aa1eb` passed Flutter CI #153: code generation, formatting, analyzer, and the full Flutter test suite. The batch warm-up patch adds deterministic operation-count regressions for the new behavior: a 50-unique-quotes × 200-pages batch profile (one 200-page warm-up, 0 per-anchor quote-scan visits, 50 candidate cache hits), warm-up/per-quote scan candidate equivalence (including overlapping matches), failure eviction + retry, skip semantics for cached/duplicate/empty quotes, ambiguity/context invariants preserved after warm-up, and service-level batch/sequential equivalence. Because the sandbox cannot run Dart, the algorithm and every new counter expectation were additionally validated against a faithful Python port of the cache/index/resolver logic before commit. Repository CI is the authoritative gate for the new commit.

The preview harness change touches no Dart code; it was verified headlessly in Chromium (43/43 DOM/pixel assertions across shell, screens, reader, selection→highlight, annotation management, search, and resume flows) plus `node --check`. Flutter CI remains the only gate for product code.

## Risks / blockers

- The development sandbox cannot install Flutter (network policy blocks `pub.dev` and Flutter SDK storage), so Dart changes here cannot be executed locally; use the branch's CI for product-code verification.
- The web preview harness is a hand-built mirror and will drift from the Flutter UI; it must never replace real platform verification, and product UI changes land in Flutter code first.
- Physical Linux/Android UX, predictive Back, large text, keyboard focus, thumbnail performance on very large PDFs, outline depth/size and atypical PDFs still need validation.
- Managed-copy repair currently requires explicit reimport of matching content; a dedicated missing-source recovery UI is not yet implemented.
- Facing-page behavior is currently left-to-right with page 1 as cover; right-to-left/manga ordering and a no-cover pairing option are not implemented.
- Spread preference is not persisted across reader sessions; persist it only if usability testing shows clear value.
- Fit commands remain one-shot; sticky fit-on-resize should be added only if testing justifies it.
- Flow remains blocked on reading-order/source-map quality; scanned PDFs need OCR for selection/search.
- Batch warm-up is scoped to one recovery pass over an open handle: single-annotation navigation still resolves one anchor per open handle, and the transient automaton costs O(total pending quote characters) memory per pass.

## Next recommended action

1. Physically validate import/open/scroll/select/Contents/Pages/Fit/Spread/Back/reopen on Linux + Android, including managed-copy repair, with 50+ stale annotations across a large PDF to exercise batch recovery in practice.
2. Consider profiling whether navigation (single-anchor) paths ever need warm-up sharing; do not add caches beyond the open handle.
3. Do not start reconstructed PDF Flow until reading-order/source-map quality is ready.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
