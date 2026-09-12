# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines). Do not turn it into a changelog.

Last updated: 2026-09-12

## Current milestone

**Phase 2: PDF Fidelity + search + source-linked annotation management + anchor recovery.**

Kola imports local documents, renders real PDFs, restores position, extracts source-linked text/geometry, provides persistent local FTS search, source-linked PDF highlighting, annotation management, conservative anchor recovery, resolved annotation navigation, recovered highlight geometry, handle-scoped PDF text caching, and CI-verified local quote-fallback recovery profiling. Flow remains disabled.

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
- `PdfrxPdfHandle` owns a disposable `PdfPageTextCache` (D-029): repeated/concurrent reads of one page share one extraction future; failures are evicted; close clears the cache.
- `PdfAnchorResolver` can emit local ephemeral `PdfAnchorRecoveryProfile` diagnostics (D-030): page-load requests, unique pages, quote-scan pages, candidates, strategy, and elapsed time.
- `PdfPageTextCache` exposes in-memory hit/miss/failure/cached-page counters for profiling; counters reset when the cache is cleared.
- `PdfrxPdfAdapter` accepts an optional recovery-profile observer for development/tests; normal app behavior does not persist or transmit diagnostics.
- Synthetic baseline is verified: 50 stale annotations over 200 pages produce 200 actual cached page loads but 10,000 quote-fallback page scans, identifying repeated string scanning as the next measured bottleneck.
- Reader paints only successfully resolved current-source geometry; unresolved stale geometry is suppressed and persisted anchors remain unchanged.
- PDF capabilities remain fidelity + text search + text selection + text annotations. Flow/ink/area annotations remain false.

## Recovery performance path

```text
AnnotationGeometryRecoveryService
  -> open one PdfrxPdfHandle
  -> PdfPageTextCache bounds extraction to unique pages
  -> PdfAnchorResolver profiles each resolution
       page requests / unique pages / quote pages / candidates / strategy / elapsed
  -> synthetic heavy baseline compares extraction reuse vs repeated quote scanning
```

## Important files

```text
lib/document/adapters/pdf/pdf_anchor_recovery_profile.dart
lib/document/adapters/pdf/pdf_anchor_resolver.dart
lib/document/adapters/pdf/pdf_page_text_cache.dart
lib/document/adapters/pdf/pdfrx_pdf_adapter.dart
test/document/adapters/pdf/pdf_anchor_recovery_profile_test.dart
test/document/adapters/pdf/pdf_page_text_cache_test.dart
```

## Invariants

- Core reading/search/annotation requires no account/network.
- Original files are never modified.
- Generic Reader/annotation code does not import pdfrx.
- Persist source coordinates/ranges, never viewer/screen coordinates.
- Ambiguous anchor recovery returns unresolved rather than guessing.
- Reader paint uses only successfully resolved current-source geometry.
- Recovery never silently mutates the persisted annotation anchor.
- PDF text cache is scoped to one open handle; no unbounded global cache.
- Recovery profiling is local/ephemeral only; no telemetry, persistence, or cloud reporting.
- Performance optimizations require repeatable evidence; do not assert machine-specific duration thresholds in CI.
- Position, coverage, and active reading time remain separate.
- AI/study systems remain out of scope; BYOC remains optional.

## Verification

PR #11 is merged on `main` as squash commit `8e4069038c725c7e800d3942b393090af1b7ae17`; implementation-head CI run 131 and exact-head run 132 passed. PR #12 profiling implementation passed CI run 136 on Flutter 3.47.4 / Dart 3.13.3: dependency resolution, Drift generation, formatting, analyzer, cache-counter tests, profiling tests including the 50×200 synthetic baseline, annotation recovery tests, search/database tests, and the existing app smoke suite all passed. This state synchronization is the only change after run 136 and requires one final exact-head CI pass before merge.

## Current risks / blockers

- Recovered geometry still needs physical validation on rotated/cropped/atypical PDFs and Linux + Android.
- Current quote-context fallback still scans every PDF page for each stale annotation; handle caching removes extraction duplication but not repeated string-scan work.
- Profiling is synthetic in CI; physical-device timing measurements are still needed before choosing thresholds or user-facing performance claims.
- Annotation management/navigation UI still needs physical UX validation.
- Scanned/image-only PDFs need local OCR for selection/search/recovery.
- Flow Mode remains blocked on reading-order/source-map quality work.

## Next recommended action

1. Merge local recovery profiling after exact-head CI.
2. Use the measured scan baseline to design a per-handle exact-quote candidate index or batched fallback resolver, then compare scan counts before/after.
3. Physically validate recovered highlight alignment and recovery timing on Linux + Android.
4. Add annotation filters/export only after management UX is stable.
5. Begin reconstructed PDF Flow after reading-order/source-map quality tests.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.

## Required update after every patch

Architecture/data-flow changes -> `PROJECT_GRAPH.md`. Durable decisions -> `DECISIONS.md`. Feature-scope changes -> relevant spec. Meaningful UX changes must remain consistent with `UX_RESEARCH.md`, `UX_VALIDATION.md`, and `VISUAL_DIRECTIONS.md`.
