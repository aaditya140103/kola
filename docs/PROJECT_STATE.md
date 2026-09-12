# Kola — Live Project State

> **Agents must update this file on every patch.** Keep it compact (target: <= 120 lines).

Last updated: 2026-09-13

## Current milestone

**Phase 2 stability/debug pass: PDF fidelity + search + source-linked annotation management/recovery.**

Feature work is paused while runtime paths are hardened. Startup/import/recovery and search revision races are contained; this patch strengthens managed-copy repair so truncated local copies are not treated as healthy.

## Current implementation

- Flutter/Dart + Riverpod + go_router; Dart floor 3.13.
- SQLite/Drift schema v2 + local FTS5.
- Managed/linked imports, streamed SHA-256 identity, real PDF fidelity and durable page/zoom resume.
- PDF source text/geometry, local search/source jumps, persistent highlights, notes/recolor/delete, conservative anchor recovery and transient recovered geometry.
- App startup awaits `pdfrxFlutterInitialize()` before mounting Kola, preventing direct PDF adapter work from racing pdfrx/PDFium initialization.
- Import detects the source before fingerprinting rather than leaving independent file-operation futures potentially unobserved after an early failure.
- Annotation geometry recovery is isolated per highlight: a thrown/corrupt anchor is skipped while other valid annotations continue to recover and render.
- Search indexing serializes work per document revision. Newer revisions queue behind older work and stale callers cannot downgrade a newer persistent index.
- Managed-copy duplicate/reimport health now requires both file existence and the expected byte length. Missing or wrong-sized managed files are recopied from the explicitly reselected matching source and remain one document identity.
- `LocalDocumentSourceStorage` replaces a wrong-sized deterministic destination through a temporary copy before returning it as healthy.
- Handle-scoped page-text and exact-quote caches remain disposable and local to one open PDF handle (D-029..D-031).
- Recovery profiling remains deterministic and operation-count based. The 50-distinct-quotes × 200-pages baseline is 10,000 cached page-string scans with only 200 underlying page-text extraction misses.
- Reader uses toolbar + Expanded source surface; Home/Library/Search push reader routes and Back restores origin with Library fallback for direct routes.
- PDF outline, lazy thumbnail navigation, Fit Width / Fit Page, and optional >= 840 dp facing-page spread remain integrated inside the PDF renderer boundary.
- Managed PDF fallback titles use the original source filename; reader entry records `lastOpenedAt`.
- PDF remains the only registered adapter/renderer. Import recognition does not imply reading support.

## Important files

- `lib/main.dart`
- `lib/document/import/document_import_service.dart`
- `lib/document/import/document_source_storage.dart`
- `test/document/import/document_import_service_test.dart`
- `lib/features/annotations/application/annotation_geometry_recovery_service.dart`
- `lib/features/search/application/document_search_service.dart`
- `test/features/search/document_search_service_test.dart`
- `lib/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart`
- `lib/features/reader/presentation/reader_screen.dart`

## Invariants

- Local reading/search/annotation requires no account/network; original files remain untouched.
- Generic reader code does not import pdfrx; PDF-engine behavior stays behind PDF boundaries.
- Readable source content must not be blocked by metadata, recovery, indexing, or annotation failures.
- Search index revisions must move forward for one document identity; stale callers cannot replace newer indexed state.
- Managed-copy repair only uses explicitly reselected matching content; it does not search arbitrary external files.
- Persist source coordinates, not screen coordinates. Ambiguous recovery stays unresolved.
- A failed annotation recovery suppresses only that failed highlight.
- Recovery paints verified current-source geometry without mutating stored anchors.
- Page-text and quote caches remain disposable and handle-scoped.
- Position progress stays separate from coverage and active reading time.
- No new format, cloud, AI or study-system scope is introduced during the stability pass.

## Verification

Stability commit `31f1333` passed Flutter CI #155. The corrected search-revision head `7dd0195` passed Flutter CI #158 including analyzer and full tests. This managed-copy patch adds a regression that truncates an existing managed file and verifies matching reimport restores the complete bytes and returns `sourceRepaired`. Repository CI is the authoritative gate for the new commit.

## Risks / blockers

- Physical Linux/Android reproduction remains essential because CI cannot cover all native PDFium/window/file-picker timing and packaging behavior.
- Several PDF renderer actions are launched asynchronously from UI callbacks; controller/disposal races still require focused defensive handling.
- `Fit Page` reads the pdfrx page-layout list without a transient-layout bounds guard; rapid resize/spread changes can race this access.
- Flow-mode persistence has an unawaited save path that should be hardened before Flow becomes enabled for any format.
- Managed-copy health now catches missing/truncated/wrong-sized files, but same-size bit corruption is not rehashed during ordinary duplicate import.
- Physical predictive Back, large text, keyboard focus, atypical/rotated/password PDFs, very large thumbnails/outlines, and packaging remain validation gaps.
- Many distinct stale quotes still scale as O(unique quotes × pages) for substring scans; optimization is deferred until stability work is complete.

## Next recommended action

1. Harden PDF renderer controller actions, transient page-layout access, selection callbacks, and reader persistence futures; add regressions where feasible.
2. Physically run import/open/scroll/select/search/annotations/Contents/Pages/Fit/Spread/Back/reopen on Linux, then Android.
3. Capture any Fedora runtime stack traces that remain after these fixes and map them to the audited paths.
4. Resume batch/multi-quote optimization only after the stability pass is green.

Do not implement cloud providers yet. Do not add AI or dedicated study systems.
