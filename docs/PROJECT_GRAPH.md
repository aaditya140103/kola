# Kola — Project Graph

Compact architecture context for agents. Read with `AGENTS.md` and `docs/PROJECT_STATE.md` before long specs.

## 1. Application architecture

```mermaid
flowchart TD
    OS[Linux / Windows / macOS / Android / iOS]
    UI[Adaptive Flutter UI]
    Domain[Kola Domain]
    DB[(SQLite / Drift + FTS5)]
    Files[(Local / Managed Files)]
    Format[FormatRegistry]
    Fidelity[FidelityRendererRegistry]
    Engines[Format Engines]
    Text[Source Text + Geometry]
    Search[Persistent Local Search]
    Annotation[Source-linked Annotations]
    KDG[Kola Document Graph]
    Flow[Flow]
    Sync[Optional BYOC]

    OS --> UI --> Domain
    Domain <--> DB
    Domain --> Format --> Engines --> Files
    Domain --> Fidelity --> Engines
    Engines --> Text --> Search --> DB
    Text --> Annotation --> DB
    Text --> KDG --> Flow
    DB -. optional .-> Sync
```

Local reading/search/annotation never depends on sync.

## 2. Import + identity

```mermaid
flowchart LR
    Pick[Native Picker] --> Detect[Format Probe]
    Pick --> Hash[Stream SHA-256] --> ID[sha256 Document ID]
    ID --> Store[Managed Copy / Linked File]
    Detect --> Registry[FormatRegistry]
    Store --> Repo[DocumentRepository]
    Registry --> Repo --> DB[(SQLite)] --> Library[Reactive Library]
```

Rules: originals untouched; identical bytes share identity; unknown formats do not mutate library; managed copies are durable.

## 3. Current PDF reader path

```mermaid
flowchart LR
    Route[reader/:documentId]
    Repo[DocumentRepository]
    Doc[KolaDocument]
    Fidelity[FidelityRendererRegistry]
    Resolver[DocumentSourceResolver]
    View[PdfrxPdfFidelityRenderer]
    PDFium[pdfrx / PDFium]
    Pages[Real PDF Pages]
    Outline[PDF Outline / Destinations]
    Contents[Contents Sheet]
    Thumbs[Lazy PdfPageView Thumbnails]
    Fit[Fit Width / Fit Page]
    Adaptive[Reader surface width]
    Spread[Facing-page layout]

    Route --> Repo --> Doc --> Fidelity --> View --> Resolver --> PDFium --> Pages
    PDFium --> Outline --> View --> Contents
    Contents -- goToDest --> View
    Pages --> Thumbs --> View
    View -- native fit matrices + goTo --> Fit --> View
    Adaptive --> View
    View -- >= 840 dp + opt-in --> Spread --> View
```

Generic Reader code does not import `pdfrx`.

Reader layout is `SafeArea -> Column -> toolbar + Expanded(fidelity surface)` so source content receives the remaining viewport rather than the toolbar height. Home/Library/Search push reader routes; toolbar Back pops to the origin, with Library as fallback for direct routes. Loading/error states also expose Back. Resume-read failures degrade to a readable source with a notice. Position-save failures are reported without blocking exit; the repository is captured before disposal for system-back flushes.

PDF structure and page-layout navigation stay inside the PDF renderer boundary. The active pdfrx document loads its outline lazily; nested nodes render through progressive disclosure in a Contents sheet; selecting a node uses its engine-native `PdfDest` with `goToDest`. The Pages sheet reuses the active `PdfDocument` and lazily renders `PdfPageView` thumbnails. Fit Width uses `calcMatrixFitWidthForPage`; Fit Page chooses the smaller native width/height fit zoom, centers the active page, and animates through `PdfViewerController.goTo`. Expanded reader surfaces can opt into a facing-page layout that keeps page 1 as the right-side cover and pairs later pages left-to-right. Compact widths force the default vertical single-page layout without discarding the session preference. Layout switches invalidate pdfrx and restore the active page. Missing/failed outlines never block page reading.

## 4. PDF source-text extraction + handle cache

```mermaid
flowchart LR
    Handle[PdfrxPdfHandle]
    Cache[Handle-scoped PdfPageTextCache]
    Page[PdfPage]
    Structured[loadStructuredText]
    Pdfrx[PdfPageText + fragments + char rects]
    Mapper[PdfTextGeometryMapper]
    Kola[DocumentTextChunk]
    Index[IndexChunk]
    Graph[KDG sourceVisualBlock]

    Handle --> Cache
    Cache -- cache miss --> Page --> Structured --> Pdfrx --> Mapper --> Kola
    Kola --> Cache
    Cache -- cached / in-flight reuse --> Kola
    Kola --> Index
    Kola --> Graph
```

PDF geometry stays in PDF page points (bottom-left origin), never viewer pixels. Cache lifetime is one open document handle; close clears it, and failed page loads are evicted for retry.

## 5. Persistent local search

```mermaid
flowchart LR
    Doc[KolaDocument] --> Fresh{index current?}
    Fresh -- no --> Adapter[DocumentAdapter] --> Chunks[IndexChunk] --> Service[DocumentSearchService] --> FTS[(SQLite FTS5)]
    Fresh -- yes --> FTS
    FTS --> Search[Global / Reader Search] --> Hit[SearchHit + DocumentLocation] --> Nav[FidelityNavigationRequest] --> PDF[PDF page jump]
```

Search is format-neutral and source-locator based.

## 6. PDF highlight creation

```mermaid
flowchart LR
    Select[pdfrx text selection]
    Ranges[PdfPageTextRange + fragment rects]
    KolaSel[DocumentTextSelection]
    Service[AnnotationCreationService]
    Anchor[AnnotationAnchor]
    Repo[AnnotationRepository]
    DB[(SQLite)]

    Select --> Ranges --> KolaSel --> Service --> Anchor --> Repo --> DB
```

Anchors preserve source locator, exact quote/context, logical range when available, per-page fallback ranges, and PDF-point geometry.

## 7. Annotation management + safe navigation

```mermaid
flowchart LR
    Panel[Annotations Panel]
    Live[annotationsProvider]
    Command[AnnotationManagementService]
    NavService[AnnotationNavigationService]
    Adapter[DocumentAdapter]
    Resolve[AnchorResolution]
    Repo[AnnotationRepository]
    DB[(SQLite)]
    Reader[FidelityNavigationRequest]
    Warn[Unresolved warning]

    DB --> Live --> Panel
    Panel -- recolor / note / delete --> Command --> Repo --> DB
    Panel -- go to annotation --> NavService --> Adapter --> Resolve
    Resolve -- resolved --> Reader
    Resolve -- unresolved --> Warn
```

Go-to never trusts a stored locator directly once anchor recovery is available.

## 8. Conservative annotation-anchor recovery

```mermaid
flowchart TD
    Anchor[AnnotationAnchor]
    Stored[Verify stored page/range]
    Multi[Verify multi-page fallback ranges]
    Logical[Verify logical range]
    Quote[Exact quote candidate lookup]
    Context[Reload candidate page + score prefix/suffix]
    Resolved[AnchorResolution: resolved]
    Unresolved[AnchorResolution: unresolved]

    Anchor --> Multi
    Multi -- verified --> Resolved
    Multi -- no --> Stored
    Stored -- exact quote matches --> Resolved
    Stored -- no --> Logical
    Logical -- exact quote matches --> Resolved
    Logical -- no --> Quote
    Quote -- none --> Unresolved
    Quote -- candidates --> Context
    Context -- unique best --> Resolved
    Context -- ambiguous --> Unresolved
```

Never silently guess. Candidate indexing changes lookup cost only; context/ambiguity verification remains authoritative.

## 9. Recovery profiling + exact-quote candidate reuse

```mermaid
flowchart LR
    Handle[PdfrxPdfHandle] --> TextCache[PdfPageTextCache]
    Handle --> QuoteIndex[PdfExactQuoteIndex]
    Resolver[PdfAnchorResolver] --> QuoteIndex
    QuoteIndex -- first quote lookup --> TextCache
    TextCache --> Scan[Scan each page once for exact quote]
    Scan --> CandidateCache[Cached source ranges for that quote]
    QuoteIndex -- repeated same quote --> CandidateCache
    CandidateCache --> Verify[Reload candidate pages + context/ambiguity verification]
    Verify --> Resolver
    Resolver --> Profile[PdfAnchorRecoveryProfile]
    Profile --> Baseline[Synthetic operation-count tests]
```

Both caches are local, disposable, and handle-scoped. The measured repeated-quote baseline is expected to fall from 10,000 quote-scan page visits (50 annotations × 200 pages) to 200, while recovery semantics remain unchanged. Unique quotes can still trigger independent scans and require separate measurement before further optimization.

## 10. Recovered highlight geometry

```mermaid
flowchart LR
    DB[(Persisted AnnotationAnchor)] --> Live[annotationsProvider]
    Live --> Recovery[AnnotationGeometryRecoveryService]
    Recovery --> Adapter[DocumentAdapter]
    Adapter --> Resolve[AnchorResolution + current source range]
    Resolve --> Text[Current DocumentTextChunk]
    Text --> Geometry[Rebuilt PDF-point geometry]
    Geometry --> Provider[recoveredAnnotationGeometryProvider]
    Provider --> Highlight[FidelityTextHighlight]
    Highlight --> Paint[PDF page paint callback]
    Resolve -- unresolved --> Suppress[Do not paint stale geometry]
```

Recovered geometry is transient. It never silently rewrites the persisted anchor. All resolutions within one recovery pass share the open PDF handle and its disposable caches.

## 11. Reading-position persistence

```mermaid
flowchart LR
    PDF[PDF Viewer] --> State[FidelityViewState] --> Debounce[400 ms] --> Reading[ReadingState] --> Repo[ReadingRepository] --> DB[(SQLite)]
    DB --> Repo --> Restore[Restore page + zoom + mode] --> PDF
```

Position is distinct from coverage and active reading time.

## 12. PDF capability state

```mermaid
flowchart TD
    PDF[PDF Adapter]
    Fidelity[Fidelity ✅]
    Nav[Page / Zoom ✅]
    Outline[Outline / Contents ✅]
    Thumbs[Thumbnails ✅]
    Fit[Fit Width / Fit Page ✅]
    Spread[Adaptive two-page spread ✅]
    Resume[Resume ✅]
    Extract[Text + Geometry ✅]
    Search[Search + source jump ✅]
    Select[Text Selection ✅]
    Highlight[Persistent Highlight ✅]
    Manage[List / resolve / jump / recolor / note / delete ✅]
    Recover[Anchor + highlight geometry recovery ✅]
    Flow[Flow ❌]
    Ink[Ink / area annotations ❌]

    PDF --> Fidelity --> Nav --> Resume
    PDF --> Outline
    PDF --> Thumbs
    PDF --> Fit
    PDF --> Spread
    PDF --> Extract --> Search
    PDF --> Select --> Highlight --> Manage --> Recover
    PDF -. future .-> Flow
    PDF -. future .-> Ink
```

Capability flags describe integrated Kola behavior, not engine primitives.

## 13. Universal adapter + fidelity boundary

```mermaid
flowchart LR
    Doc[KolaDocument] --> Adapter[DocumentAdapter] --> Handle[DocumentHandle]
    Handle --> Fidelity[Fidelity]
    Handle --> Text[DocumentTextChunk]
    Text --> Index[IndexChunk]
    Text --> KDG[KDG + Source Map]
    Handle --> Resolve[AnchorResolution]
    Resolve --> Location[DocumentLocation]
    Resolve --> Geometry[Transient Source Geometry]
    Location --> Request[FidelityNavigationRequest] --> Fidelity
```

Engine-specific objects are mapped to Kola-owned models before leaving adapters. PDF outline destinations, thumbnail previews, fit transforms, and facing-page layout are renderer-local interactions and do not escape into generic Reader/domain APIs.

## 14. Persistence boundary

```mermaid
flowchart LR
    DB[(SQLite / Drift + FTS5)] --> Repos[Document / Reading / Annotation / Search Repositories]
    Repos --> Models[Kola Domain Models] --> Providers[Riverpod] --> UI[Home / Library / Search / Insights / Reader]
```

Drift row types never escape the data layer; datetime raw writes use UTC ISO-8601.

## 15. Adaptive-native policy

```mermaid
flowchart LR
    Platform[Platform] --> Policy[Kola Adaptive Policy]
    Window[Window Size] --> Policy
    Input[Touch / Mouse / Keyboard / Stylus] --> Policy
    A11y[Accessibility] --> Policy
    Policy --> UI[Native-feeling Presentation]
```

## 16. Optional BYOC

```mermaid
flowchart LR
    DB[(Local SQLite)] -. optional .-> Projection[Versioned Sync Records] -.-> Backend[User SyncBackend] -.-> Cloud[(User Cloud / Folder)]
```

Never sync the live SQLite file. Sync failures never block local reading.

## 17. Agent patch protocol

```mermaid
flowchart LR
    Task --> Read[AGENTS + STATE + GRAPH] --> Change --> Test --> State[Update PROJECT_STATE] --> Graph[Update graph if architecture changed] --> Decision[Update DECISIONS if needed] --> Done
```
