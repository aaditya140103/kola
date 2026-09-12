# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-13

## Current milestone

**Phase 2: PDF fidelity + search + source-linked annotation management/recovery; reader continuity and adaptive page layout.**

PDF reader continuity and adaptive page controls are merged. This patch adds the previously missing many-unique-quotes recovery baseline so the next indexing change is driven by measured algorithmic cost rather than assumption.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + local FTS5.
- Managed/linked imports, streamed SHA-256 identity, real PDF fidelity and durable page/zoom resume.
- PDF source text/geometry, local search/source jumps, persistent highlights, notes/recolor/delete, conservative anchor recovery and transient recovered geometry.
- Handle-scoped page-text and exact-quote caches remain disposable and local to one open PDF handle (D-029..D-031).
- Recovery profiling is deterministic and operation-count based; it does not depend on machine-specific timing thresholds.
- Existing repeated-quote baseline: 50 stale annotations sharing one quote across 200 pages require 200 quote-scan page visits after candidate reuse, rather than 10,000 independent scans.
- New unique-quote baseline: 50 distinct stale quotes across 200 pages produce 10,000 quote-scan page visits and 50 exact-quote cache misses, while `PdfPageTextCache` still limits underlying page-text extraction misses to 200.
- The unique-quote result isolates the remaining cost: repeated substring scans over already-cached page text, not repeated PDF/PDFium text extraction.
- Reader uses toolbar + Expanded source surface; compact toolbar and PDF page controls wrap.
- Home/Library push reader routes, matching Search; Back restores origin with Library fallback for direct routes.
- PDF outline, lazy thumbnail navigation, Fit Width / Fit Page, and optional >= 840 dp facing-page spread remain integrated inside the PDF renderer boundary.
- Managed PDF fallback titles use the original source filename rather than the managed hash filename.
- Reader entry records `lastOpenedAt` once per reader instance without mutating structural revision/`updatedAt`.
- Missing managed copies can be repaired by reimporting matching bytes without creating a duplicate document identity.
- PDF remains the only registered adapter/renderer. Import recognition does not imply reading support.

## Important files

- `lib/document/adapters/pdf/pdf_anchor_recovery_profile.dart`
- `lib/document/adapters/pdf/pdf_anchor_resolver.dart`
- `lib/document/adapters/pdf/pdf_exact_quote_index.dart`
- `lib/document/adapters/pdf/pdf_page_text_cache.dart`
- `test/document/adapters/pdf/pdf_anchor_recovery_profile_test.dart`
- `docs/PROJECT_GRAPH.md`

## Invariants

- Local reading/search/annotation requires no account/network; original files remain untouched.
- Generic reader code does not import pdfrx; PDF-engine behavior stays behind PDF boundaries.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- Exact-quote candidates remain advisory; every recovered candidate is still verified with current page text and context/ambiguity rules.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Page-text and quote caches remain disposable and handle-scoped.
- Profiling remains local/ephemeral and uses deterministic counters for CI assertions.
- Position progress stays separate from coverage and active reading time.
- No new format, cloud, AI or study-system scope is introduced.

## Verification

Continuity commit `c4aa1eb` passed Flutter CI #153: code generation, formatting, analyzer, and the full Flutter test suite. This patch adds a deterministic 50-unique-quotes × 200-pages recovery regression that separates exact-quote string-scan work from cached PDF page extraction. Repository CI is the authoritative gate for the new commit.

## Risks / blockers

- Physical Linux/Android UX, predictive Back, large text, keyboard focus, thumbnail performance on very large PDFs, outline depth/size and atypical PDFs still need validation.
- Managed-copy repair currently requires explicit reimport of matching content; a dedicated missing-source recovery UI is not yet implemented.
- Facing-page behavior is currently left-to-right with page 1 as cover; right-to-left/manga ordering and a no-cover pairing option are not implemented.
- Spread preference is not persisted across reader sessions; persist it only if usability testing shows clear value.
- Fit commands remain one-shot; sticky fit-on-resize should be added only if testing justifies it.
- Flow remains blocked on reading-order/source-map quality; scanned PDFs need OCR for selection/search.
- Many distinct stale quotes still scale as O(unique quotes × pages) for exact substring scans even though PDF extraction is bounded by the page cache.

## Next recommended action

1. Prototype a handle-scoped batch/multi-quote candidate lookup for one recovery pass, with a target of reducing the 50 × 200 unique-quote baseline from 10,000 page-string scans toward one 200-page pass while preserving context scoring and ambiguity behavior.
2. Compare the optimized deterministic operation counts against this baseline before retaining the change; do not add a global/unbounded cache.
3. Physically validate import/open/scroll/select/Contents/Pages/Fit/Spread/Back/reopen on Linux + Android, including managed-copy repair.
4. Do not start reconstructed PDF Flow until reading-order/source-map quality is ready.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
