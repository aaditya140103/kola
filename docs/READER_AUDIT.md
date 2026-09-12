# Reader architecture and build audit — 2026-09-12

## Scope and evidence

Inspected `main` at `b62bfc93573cedb0e63e59bddc58dfc199329654`, the repository instructions, live state, graph, architecture, roadmap, UX evidence/spec/validation, import/storage/providers, router, reader, PDF adapter/renderer, repositories and tests. Reviewed the recent search/annotation/recovery commit sequence. GitHub reported no open issues/PRs; baseline main CI run 144 passed. The original README was still describing Phase 0 and was materially behind the code.

## Architecture actually implemented

- Flutter/Dart owns the UI; Riverpod connects app-owned models and repository services; go_router provides an adaptive shell and a separate reader route.
- Native picker -> magic/container/extension detection -> streamed SHA-256 identity -> managed copy or linked file -> document repository -> SQLite/Drift schema v2 -> reactive Library/Home.
- Format registry and fidelity-renderer registry each register only PDF. Broader format detection is infrastructure, not a collection of implemented readers.
- Reader resolves its document and saved state, chooses capabilities and renderer, and supplies app-owned position/navigation/selection/highlight values. Generic reader code does not import pdfrx.
- PDFium/pdfrx owns page rendering and extraction behind the adapter. Kola converts text ranges and PDF-point geometry to source-linked models.
- Persistent FTS search indexes extracted text and returns document/source locations; reader search and annotation navigation issue fidelity navigation requests.
- Highlights persist hybrid quote/context/range/geometry anchors. Recovery verifies current source content conservatively, suppresses unresolved geometry, and uses disposable per-handle text/quote caches.
- Position is saved with a debounce and remains separate from coverage and active reading time. No account or cloud service is on the local reading path.

## Reported failures: bugs versus deferred features

| Behavior | Classification | Evidence and repair |
| --- | --- | --- |
| PDF appears not to open | Implemented functionality with a layout bug | The outer Stack sized itself from its non-positioned toolbar. `Positioned.fill` consequently gave the renderer only the toolbar-sized region, covered by chrome. Replaced it with a Column and Expanded source surface; regression checks actual content position and usable interactions. |
| Back from a document does nothing/errors | Navigation bug | Home/Library used `go`, replacing the shell route, while reader used `pop`. Changed entry to `push`, retained Search's existing push, and added Library fallback for direct routes. |
| Loading/error reader is hard to leave | Navigation bug | Loading had no Back; errors popped without checking history. All such states now expose a safe exit. |
| Tapping content hides the exit | Interaction bug | A parent gesture toggled chrome but competed with engine selection/gestures. Controls remain visible for Phase 2; tested Focus Mode remains future work. |
| Bad saved state blocks readable source | Graceful-degradation bug | Restore error previously replaced the whole reader with an error. PDF now opens from its initial location with a visible warning. |
| Save failure prevents Back/unhandled disposal access | Lifecycle bug | Exit awaited a throwing write, and disposal read Riverpod through `ref`. Save errors are contained and repository access is captured while mounted. |
| Narrow reader controls overflow | Adaptive-layout bug | A 320px widget test reproduced toolbar overflow. Actions wrap on narrow layouts. |
| TXT/EPUB/office/comic imports lack a reader | Intentionally deferred | Detector recognizes them, but registries have no corresponding adapters/renderers. TXT/markup/EPUB are roadmap Phase 5; broader formats come later. |
| Flow Mode unavailable | Intentionally deferred | PDF `flowMode` is false; graph output remains source-preserving page blocks rather than trustworthy semantic reflow. |

A synthetic real PDF now opens and renders through PDFium, including a managed copy whose original URI no longer exists. This verifies the source/engine path for that case; it does not prove every user PDF or platform works.

## Current build state and gaps

The source is a Flutter package with a bootstrap script to generate native platform projects. Dart minimum is 3.13. The current milestone is Phase 2 with selected later search/annotation capabilities integrated, not completion of every Phase 2/3/4 deliverable. Outline, thumbnails, alternate page layouts, annotation undo/export, broad format renderers, Flow, OCR, full reading analytics, Focus/history/tabs and sync still require work.

The original smoke suite only opened an empty Home. Real-PDF extraction was gated behind an environment variable, so a passing baseline CI did not establish usable reader layout or working native PDF rendering. The patch adds reader interaction/layout regressions and makes native extraction/rendering tests locate Flutter's built PDFium asset explicitly and fail if missing.

Other inspected gaps outside this repair: PDF fallback metadata derives its title from the managed hash filename; document opening does not currently update `lastOpenedAt`; reimporting the exact same source can return early even if a managed copy has disappeared; several shell actions remain placeholders. These are follow-ups, not claims of completed functionality.

## Validation and limits

Local validation passed all 76 tests with no skips, dependency resolution, Drift generation, the analyzer (no issues), existing persistence/search/annotation/recovery tests, reader interaction and compact layout regressions, and real PDFium rendering/text extraction. A Linux release build from an isolated copy succeeded and contains libpdfium.so and libsqlite3.so. The test fixture is generated locally and contains no user document. No database migration or source-file modification is introduced.

Physical Linux/Android testing, packaging on non-Linux targets, predictive Back, large text, password prompts, and atypical PDF geometry remain follow-up checks. The user’s exact file/device was not available, so the repair targets independently reproduced code defects rather than claiming a device-specific reproduction.

## Next steps after this repair

1. Physically validate import/open/scroll/select/Back/reopen on Linux and Android, including rotated/cropped PDFs and large text.
2. Finish reader continuity details such as `lastOpenedAt`, title fallback, missing managed-copy repair, and remaining Phase 2 outline/thumbnail/navigation work.
3. Continue the prior recovery plan: many-unique-quotes profile before further indexing optimization; source-map and reading-order tests before reconstructed PDF Flow.
4. Add TXT/markup/EPUB through the shared adapter and graph boundaries rather than a reader-only parser. Keep cloud providers and AI/study systems out of this phase.

Because PDF display and ordinary Back are existing functionality, repairing them takes precedence over adding the next deferred feature, consistent with the roadmap's reader-correctness rule.
