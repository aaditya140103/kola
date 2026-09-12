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

`DocumentTextChunk` preserves full page text, per-character rectangles, fragment ranges/bounds/direction, page extent, rotation, and source location. PDF geometry stays in PDF page points (bottom-left origin), never viewer pixels.

## 5. Persistent local search

```mermaid
flowchart LR
    Doc[KolaDocument]
    Fresh{revision + extractor version current?}
    Adapter[DocumentAdapter]
    Chunks[IndexChunk stream]
    Service[DocumentSearchService]
    FTS[(SQLite FTS5)]
    Global[Global Search]
    Reader[Reader Search]
    Hit[SearchHit + DocumentLocation]
    Nav[FidelityNavigationRequest]
    PDF[PDF page jump]

    Doc --> Fresh
    Fresh -- no --> Adapter --> Chunks --> Service --> FTS
    Fresh -- yes --> FTS
    FTS --> Global --> Hit
    FTS --> Reader --> Hit --> Nav --> PDF
```

Index rows store document ID, stable source locator, section label, hit kind, and text. Global search includes metadata + content. Reader search returns content hits only. A document revision or extractor-version change invalidates the cached index.

## 6. PDF text selection + highlight persistence

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

Persisted highlight anchors contain stable source locator, exact quote, prefix/suffix context, logical character offsets for single-page selections, per-page fallback ranges, and source-native PDF rectangles. Rendering reads only Kola-owned geometry; screen/viewer coordinates are never persisted.

## 7. Reading-position persistence loop

```mermaid
flowchart LR
    PDF[PDF Viewer]
    State[FidelityViewState]
    Debounce[400 ms Debounce]
    Reading[ReadingState]
    Repo[ReadingRepository]
    DB[(SQLite)]
    Restore[Restore page + zoom + view mode]

    PDF -- page/zoom --> State --> Debounce --> Reading --> Repo --> DB
    DB --> Repo --> Reading --> Restore --> PDF
```

For PDF, `ReadingState.location` uses `scheme=pdf` + 1-based page. Position is distinct from coverage and active reading time.

## 8. PDF capability state

```mermaid
flowchart TD
    PDF[PDF Adapter]
    Fidelity[Fidelity ✅]
    Nav[Page / Zoom ✅]
    Resume[Resume Position ✅]
    Extract[Text + Geometry ✅]
    Index[Persistent FTS Index ✅]
    Search[Global + Reader Search ✅]
    Jump[Source-page Navigation ✅]
    Select[Text Selection ✅]
    Highlight[Persistent Highlight ✅]
    Flow[Flow ❌]
    Notes[Note UI ❌]

    PDF --> Fidelity --> Nav --> Resume
    PDF --> Extract --> Index --> Search --> Jump
    PDF --> Select --> Highlight
    PDF -. future .-> Flow
    PDF -. future .-> Notes
```

Capability flags describe integrated user-facing Kola behavior. PDF advertises fidelity, text search, text selection, and source-linked text annotations after the highlight path passes CI/device validation. Flow and note-editing UI remain separate work.

## 9. Universal adapter + fidelity boundary

```mermaid
flowchart LR
    Doc[KolaDocument] --> Adapter[DocumentAdapter] --> Handle[DocumentHandle]
    Handle --> Fidelity[Fidelity]
    Handle --> Text[DocumentTextChunk Stream]
    Text --> Index[Index Chunks]
    Text --> KDG[KDG + Source Map]
    Handle --> Resolve[Annotation Resolution]
    Location[DocumentLocation] --> Request[FidelityNavigationRequest] --> Fidelity
```

`DocumentAdapter.open()` receives `KolaDocument`, preserving stable identity across file moves. Engine-specific text objects are mapped to Kola-owned source geometry before leaving the adapter. Search navigation uses Kola source locations rather than package controllers.

## 10. Flow + annotation invariant

```mermaid
flowchart LR
    Source[Source] --> Block[KDG Block] --> Flow[Flow Block] --> Selection[Selection] --> Anchor[Hybrid Anchor]
    Source --> Map[Source Map] --> Anchor --> Back[Resolve Back] --> Source
```

Never enable annotatable Flow/selection unless it resolves back to source reliably.

## 11. Persistence boundary

```mermaid
flowchart LR
    DB[(SQLite / Drift + FTS5)] --> Repos[Document / Reading / Annotation / Search Repositories]
    Repos --> Models[Kola Domain Models] --> Providers[Riverpod] --> UI[Home / Library / Search / Insights / Reader]
```

Drift row types never escape the data layer. Raw datetime writes use UTC ISO-8601 strings. Search is local-only and FTS rows are removed when a document is deleted.

## 12. Adaptive-native policy

```mermaid
flowchart LR
    Platform[Platform] --> Policy[Kola Adaptive Policy]
    Window[Window Size] --> Policy
    Input[Touch / Mouse / Keyboard / Stylus] --> Policy
    A11y[Accessibility] --> Policy
    Policy --> UI[Native-feeling Presentation]
```

Semantics stay consistent; navigation/chrome/menus/sheets/back/scrollbars/density adapt.

## 13. Optional BYOC

```mermaid
flowchart LR
    DB[(Local SQLite)] -. optional .-> Projection[Versioned Sync Records] -.-> Backend[User SyncBackend] -.-> Cloud[(User Cloud / Folder)]
```

Never sync the live SQLite file. Sync failures never block local reading.

## 14. Agent patch protocol

```mermaid
flowchart LR
    Task --> Read[AGENTS + STATE + GRAPH] --> Change --> Test --> State[Update PROJECT_STATE] --> Graph[Update graph if architecture changed] --> Decision[Update DECISIONS if needed] --> Done
```
