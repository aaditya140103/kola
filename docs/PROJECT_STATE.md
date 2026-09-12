# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked annotation management + anchor recovery.**

Kola imports local documents, renders real PDFs, restores position, extracts source-linked text/geometry, provides persistent local FTS search, source-linked PDF highlighting, annotation management, conservative anchor recovery, resolved annotation navigation, recovered highlight geometry, handle-scoped PDF text caching, recovery profiling, and CI-verified exact-quote candidate reuse for repeated fallback recovery. Flow remains disabled.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + app-owned FTS5 search.
- Import: format probe + streamed SHA-256 -> managed copy or explicit linked source.
- PDF engine: `pdfrx ^2.6.1` / PDFium behind Kola adapter/renderer boundaries.
- PDF fidelity: progressive render, page/zoom/navigation, durable resume.
- PDF source extraction: structured text + native PDF-point geometry.
- Search: persistent local FTS5, lazy freshness, global + reader search, source-page jump.
- PDF selection -> hybrid `AnnotationAnchor` -> SQLite -> live highlight repaint.
- Annotation panel supports list/jump/recolor/note/delete; edits preserve anchors and deletes use tombstones.
- Conservative `AnchorResolution` recovery + resolved navigation + transient recovered geometry are merged (D-026..D-028).
- `PdfrxPdfHandle` owns disposable page-text caching (D-029) and local recovery profiling is available (D-030).
- `PdfrxPdfHandle` also owns a handle-scoped `PdfExactQuoteIndex` (D-031): first lookup for one exact quote scans page text once; later identical-quote recoveries reuse source candidate positions and still run normal context/ambiguity verification.
- Quote candidate scans are disposable, in-memory, failure-evicting, and cleared with the document handle.
- Verified synthetic baseline: 50 stale annotations × 200 pages dropped from 10,000 quote-scan page visits to 200 while page extraction remained bounded to 200 unique pages.
- Reader paints only successfully resolved current-source geometry; unresolved stale geometry is suppressed and persisted anchors remain unchanged.
- PDF capabilities remain fidelity + text search + text selection + text annotations. Flow/ink/area annotations remain false.

## Recovery performance path

```text
AnnotationGeometryRecoveryService
  -> open one PdfrxPdfHandle
  -> PdfPageTextCache bounds extraction to unique pages
  -> PdfExactQuoteIndex
       first exact quote -> scan pages once -> candidate positions
       same quote later -> reuse candidates, 0 quote-scan pages
  -> PdfAnchorResolver reloads candidate pages from cache
  -> prefix/suffix context + ambiguity rules remain authoritative
```

## Important files

```text
lib/document/adapters/pdf/pdf_exact_quote_index.dart
lib/document/adapters/pdf/pdf_anchor_recovery_profile.dart
lib/document/adapters/pdf/pdf_anchor_resolver.dart
lib/document/adapters/pdf/pdf_page_text_cache.dart
lib/document/adapters/pdf/pdfrx_pdf_adapter.dart
test/document/adapters/pdf/pdf_exact_quote_index_test.dart
test/document/adapters/pdf/pdf_exact_quote_index_resolver_integration_test.dart
test/document/adapters/pdf/pdf_anchor_recovery_profile_test.dart
```

## Invariants

- Core reading/search/annotation requires no account/network.
- Original files are never modified.
- Generic Reader/annotation code does not import pdfrx.
- Persist source coordinates/ranges, never viewer/screen coordinates.
- Ambiguous anchor recovery returns unresolved rather than guessing.
- Candidate indexing accelerates lookup only; it never bypasses context verification or ambiguity checks.
- Reader paint uses only successfully resolved current-source geometry.
- Recovery never silently mutates the persisted annotation anchor.
- PDF text and quote caches are scoped to one open handle; no unbounded global cache.
- Failed page/quote loads are evicted so later work can retry.
- Recovery profiling is local/ephemeral only; no telemetry, persistence, or cloud reporting.
- Performance optimizations require repeatable evidence; do not assert machine-specific duration thresholds in CI.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #12 is merged on `main` as squash commit `d5aa093a485a3cdd7090f70fc94edacc78bf3fa8`; CI runs 136 and 137 passed the profiling baseline and full suite. PR #13 implementation-head CI run 141 passed Flutter 3.47.4 / Dart 3.13.3 dependency resolution, Drift generation, formatting, analyzer, exact-quote index reuse/concurrency/retry tests, resolver ambiguity/context tests, the 50×200 regression proving 10,000 -> 200 quote-scan page visits, annotation recovery tests, search/database tests, and the existing app smoke suite. This state synchronization is the only change after run 141 and requires one final exact-head CI pass before merge.

## Current risks / blockers

- Recovered geometry still needs physical validation on rotated/cropped/atypical PDFs and Linux + Android.
- Exact-quote candidate caching strongly helps repeated identical quotes; many unique stale quotes can still each require a full-document scan. Measure that workload before adding n-gram/token indexing or a batched resolver.
- Profiling is synthetic in CI; physical-device timing measurements are still needed before choosing thresholds or user-facing performance claims.
- Annotation management/navigation UI still needs physical UX validation.
- Scanned/image-only PDFs need local OCR for selection/search/recovery.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Merge exact-quote candidate reuse after exact-head CI.
2. Add a synthetic many-unique-quotes profile before deciding whether batched fallback or n-gram/token indexing is justified.
3. Physically validate recovered highlight alignment and recovery timing on Linux + Android.
4. Begin reconstructed PDF Flow after reading-order/source-map quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
