# Kola — Project Graph

Compact architecture context for agents. Read with `AGENTS.md` and `docs/PROJECT_STATE.md` before long specs.

## 1. Application architecture

```mermaid
flowchart TD
    OS[Linux / Windows / macOS / Android / iOS]
    UI[Adaptive Flutter UI]
    Domain[Kola Domain]
    DB[(SQLite / Drift)]
    Files[(Local / Managed Files)]
    Format[FormatRegistry]
    Fidelity[FidelityRendererRegistry]
    Engines[Format Engines]
    Text[Source Text + Geometry]
    KDG[Kola Document Graph]
    Flow[Flow / Search / Annotations]
    Sync[Optional BYOC]

    OS --> UI --> Domain
    Domain <--> DB
    Domain --> Format --> Engines --> Files
    Domain --> Fidelity --> Engines
    Engines --> Text --> KDG --> Flow
    DB -. optional .-> Sync
```

Local reading never depends on sync.

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

## 5. Reading-position persistence loop

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

## 6. PDF capability state

```mermaid
flowchart TD
    PDF[PDF Adapter]
    Fidelity[Fidelity ✅]
    Nav[Page / Zoom ✅]
    Resume[Resume Position ✅]
    Extract[Text + Geometry ✅]
    Index[Index Chunks ✅]
    Flow[Flow ❌]
    Search[Search UI/Index Persistence ❌]
    Select[Text Selection ❌]
    Annotate[Annotations ❌]

    PDF --> Fidelity --> Nav --> Resume
    PDF --> Extract --> Index
    PDF -. future .-> Flow
    PDF -. future .-> Search
    PDF -. future .-> Select
    PDF -. future .-> Annotate
```

Capability flags describe integrated user-facing Kola behavior, not raw engine primitives. PDF still advertises fidelity only until search/selection/annotation integrations exist.

## 7. Universal adapter boundary

```mermaid
flowchart LR
    Doc[KolaDocument] --> Adapter[DocumentAdapter] --> Handle[DocumentHandle]
    Handle --> Fidelity[Fidelity]
    Handle --> Text[DocumentTextChunk Stream]
    Text --> Index[Index Chunks]
    Text --> KDG[KDG + Source Map]
    Handle --> Resolve[Annotation Resolution]
```

`DocumentAdapter.open()` receives `KolaDocument`, preserving stable identity across file moves. Engine-specific text objects are mapped to Kola-owned source geometry before leaving the adapter.

## 8. Flow + annotation invariant

```mermaid
flowchart LR
    Source[Source] --> Block[KDG Block] --> Flow[Flow Block] --> Selection[Selection] --> Anchor[Hybrid Anchor]
    Source --> Map[Source Map] --> Anchor --> Back[Resolve Back] --> Source
```

Never enable annotatable Flow/selection unless it resolves back to source reliably.

## 9. Persistence boundary

```mermaid
flowchart LR
    DB[(SQLite / Drift)] --> Repos[Document / Reading / Annotation Repositories]
    Repos --> Models[Kola Domain Models] --> Providers[Riverpod] --> UI[Home / Library / Insights / Reader]
```

Drift row types never escape the data layer. Raw datetime writes use UTC ISO-8601 strings.

## 10. Adaptive-native policy

```mermaid
flowchart LR
    Platform[Platform] --> Policy[Kola Adaptive Policy]
    Window[Window Size] --> Policy
    Input[Touch / Mouse / Keyboard / Stylus] --> Policy
    A11y[Accessibility] --> Policy
    Policy --> UI[Native-feeling Presentation]
```

Semantics stay consistent; navigation/chrome/menus/sheets/back/scrollbars/density adapt.

## 11. Optional BYOC

```mermaid
flowchart LR
    DB[(Local SQLite)] -. optional .-> Projection[Versioned Sync Records] -.-> Backend[User SyncBackend] -.-> Cloud[(User Cloud / Folder)]
```

Never sync the live SQLite file. Sync failures never block local reading.

## 12. Agent patch protocol

```mermaid
flowchart LR
    Task --> Read[AGENTS + STATE + GRAPH] --> Change --> Test --> State[Update PROJECT_STATE] --> Graph[Update graph if architecture changed] --> Decision[Update DECISIONS if needed] --> Done
```
