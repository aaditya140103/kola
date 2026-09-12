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
    KDG[Kola Document Graph]
    Flow[Flow / Search / Annotations]
    Sync[Optional BYOC]

    OS --> UI --> Domain
    Domain <--> DB
    Domain --> Format --> Engines --> Files
    Domain --> Fidelity --> Engines
    Engines --> KDG --> Flow
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

## 4. Reading-position persistence loop

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

For PDF, `ReadingState.location` is source-based:

```text
scheme: pdf
data.page: 1-based page number
zoom: viewer zoom ratio
positionProgress: page / pageCount
viewMode: fidelity
```

Position is distinct from coverage and active reading time. Reader flushes pending state when leaving.

## 5. PDF capability state

```mermaid
flowchart TD
    PDF[PDF Adapter]
    Fidelity[Fidelity ✅]
    Nav[Page / Zoom ✅]
    Resume[Resume Position ✅]
    Flow[Flow ❌]
    Search[Search ❌]
    Select[Text Selection ❌]
    Annotate[Annotations ❌]

    PDF --> Fidelity --> Nav --> Resume
    PDF -. future .-> Flow
    PDF -. future .-> Search
    PDF -. future .-> Select
    PDF -. future .-> Annotate
```

Capability flags describe integrated Kola behavior, not raw engine features.

## 6. Universal adapter boundary

```mermaid
flowchart LR
    Doc[KolaDocument] --> Adapter[DocumentAdapter] --> Handle[DocumentHandle]
    Handle --> Fidelity[Fidelity]
    Handle --> Extract[Semantic Extraction] --> KDG[KDG + Source Map]
    Handle --> Index[Index Chunks]
    Handle --> Resolve[Annotation Resolution]
```

`DocumentAdapter.open()` receives `KolaDocument`, preserving stable document identity across file moves.

## 7. Flow + annotation invariant

```mermaid
flowchart LR
    Source[Source] --> Block[KDG Block] --> Flow[Flow Block] --> Selection[Selection] --> Anchor[Hybrid Anchor]
    Source --> Map[Source Map] --> Anchor --> Back[Resolve Back] --> Source
```

Never enable annotatable Flow/selection unless it resolves back to source reliably.

## 8. Persistence boundary

```mermaid
flowchart LR
    DB[(SQLite / Drift)] --> Repos[Document / Reading / Annotation Repositories]
    Repos --> Models[Kola Domain Models] --> Providers[Riverpod] --> UI[Home / Library / Insights / Reader]
```

Drift row types never escape the data layer. Raw datetime writes use UTC ISO-8601 strings.

## 9. Adaptive-native policy

```mermaid
flowchart LR
    Platform[Platform] --> Policy[Kola Adaptive Policy]
    Window[Window Size] --> Policy
    Input[Touch / Mouse / Keyboard / Stylus] --> Policy
    A11y[Accessibility] --> Policy
    Policy --> UI[Native-feeling Presentation]
```

Semantics stay consistent; navigation/chrome/menus/sheets/back/scrollbars/density adapt.

## 10. Optional BYOC

```mermaid
flowchart LR
    DB[(Local SQLite)] -. optional .-> Projection[Versioned Sync Records] -.-> Backend[User SyncBackend] -.-> Cloud[(User Cloud / Folder)]
```

Never sync the live SQLite file. Sync failures never block local reading.

## 11. Agent patch protocol

```mermaid
flowchart LR
    Task --> Read[AGENTS + STATE + GRAPH] --> Change --> Test --> State[Update PROJECT_STATE] --> Graph[Update graph if architecture changed] --> Decision[Update DECISIONS if needed] --> Done
```
