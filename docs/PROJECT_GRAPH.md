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

    Route --> Repo --> Doc --> Fidelity --> View --> Resolver --> PDFium --> Pages
```

Generic Reader code does not import `pdfrx`.

## 4. PDF source-text extraction

```mermaid
flowchart LR
    Handle[PdfrxPdfHandle]
    Page[PdfPage]
    Structured[loadStructuredText]
    Pdfrx[PdfPageText + fragments + char rects]
    Mapper[PdfTextGeometryMapper]
    Kola[DocumentTextChunk]
    Index[IndexChunk]
    Graph[KDG sourceVisualBlock]

    Handle --> Page --> Structured --> Pdfrx --> Mapper --> Kola
    Kola --> Index
    Kola --> Graph
```

PDF geometry stays in PDF page points (bottom-left origin), never viewer pixels.

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
    Live[annotationsProvider]
    Highlight[FidelityTextHighlight]
    Paint[PDF page paint callback]

    Select --> Ranges --> KolaSel --> Service --> Anchor --> Repo --> DB
    DB --> Live --> Highlight --> Paint
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
    Paint[Highlight repaint]

    DB --> Live --> Panel
    Panel -- recolor / note / delete --> Command --> Repo --> DB
    Panel -- go to annotation --> NavService --> Adapter --> Resolve
    Resolve -- resolved --> Reader
    Resolve -- unresolved --> Warn
    DB --> Live --> Paint
```

Recolor/note edits preserve the source anchor and increment revision. Delete writes `deletedAt`; live queries hide tombstones. Go-to never trusts a stored locator directly once anchor recovery is available.

## 8. Conservative annotation-anchor recovery

```mermaid
flowchart TD
    Anchor[AnnotationAnchor]
    Stored[Verify stored page/range]
    Multi[Verify multi-page fallback ranges]
    Logical[Verify logical range]
    Quote[Search exact quote]
    Context[Score prefix/suffix context]
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
    Quote -- matches --> Context
    Context -- unique best --> Resolved
    Context -- ambiguous --> Unresolved
```

Never silently guess. `AnchorResolution` reports strategy/confidence/reason. An ambiguous or missing quote remains unresolved rather than attaching to incorrect text after a source revision.

## 9. Reading-position persistence

```mermaid
flowchart LR
    PDF[PDF Viewer] --> State[FidelityViewState] --> Debounce[400 ms] --> Reading[ReadingState] --> Repo[ReadingRepository] --> DB[(SQLite)]
    DB --> Repo --> Restore[Restore page + zoom + mode] --> PDF
```

Position is distinct from coverage and active reading time.

## 10. PDF capability state

```mermaid
flowchart TD
    PDF[PDF Adapter]
    Fidelity[Fidelity ✅]
    Nav[Page / Zoom ✅]
    Resume[Resume ✅]
    Extract[Text + Geometry ✅]
    Search[Search + source jump ✅]
    Select[Text Selection ✅]
    Highlight[Persistent Highlight ✅]
    Manage[List / resolve / jump / recolor / note / delete ✅]
    Recover[Conservative anchor recovery ✅]
    Flow[Flow ❌]
    Ink[Ink / area annotations ❌]

    PDF --> Fidelity --> Nav --> Resume
    PDF --> Extract --> Search
    PDF --> Select --> Highlight --> Manage --> Recover
    PDF -. future .-> Flow
    PDF -. future .-> Ink
```

Capability flags describe integrated Kola behavior, not engine primitives.

## 11. Universal adapter + fidelity boundary

```mermaid
flowchart LR
    Doc[KolaDocument] --> Adapter[DocumentAdapter] --> Handle[DocumentHandle]
    Handle --> Fidelity[Fidelity]
    Handle --> Text[DocumentTextChunk]
    Text --> Index[IndexChunk]
    Text --> KDG[KDG + Source Map]
    Handle --> Resolve[AnchorResolution]
    Resolve --> Location[DocumentLocation]
    Location --> Request[FidelityNavigationRequest] --> Fidelity
```

Engine-specific objects are mapped to Kola-owned models before leaving adapters. Annotation navigation must consume `AnchorResolution`; unresolved anchors do not generate a fidelity request.

## 12. Persistence boundary

```mermaid
flowchart LR
    DB[(SQLite / Drift + FTS5)] --> Repos[Document / Reading / Annotation / Search Repositories]
    Repos --> Models[Kola Domain Models] --> Providers[Riverpod] --> UI[Home / Library / Search / Insights / Reader]
```

Drift row types never escape the data layer; datetime raw writes use UTC ISO-8601.

## 13. Adaptive-native policy

```mermaid
flowchart LR
    Platform[Platform] --> Policy[Kola Adaptive Policy]
    Window[Window Size] --> Policy
    Input[Touch / Mouse / Keyboard / Stylus] --> Policy
    A11y[Accessibility] --> Policy
    Policy --> UI[Native-feeling Presentation]
```

## 14. Optional BYOC

```mermaid
flowchart LR
    DB[(Local SQLite)] -. optional .-> Projection[Versioned Sync Records] -.-> Backend[User SyncBackend] -.-> Cloud[(User Cloud / Folder)]
```

Never sync the live SQLite file. Sync failures never block local reading.

## 15. Agent patch protocol

```mermaid
flowchart LR
    Task --> Read[AGENTS + STATE + GRAPH] --> Change --> Test --> State[Update PROJECT_STATE] --> Graph[Update graph if architecture changed] --> Decision[Update DECISIONS if needed] --> Done
```
