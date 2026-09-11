# Kola — Project Graph

Compact architecture context for agents. Read with `AGENTS.md` and `docs/PROJECT_STATE.md` before opening long specs.

## 1. Application architecture

```mermaid
flowchart TD
    OS[Linux / Windows / macOS / Android / iOS]
    Shell[Adaptive Native Shell]
    UI[Flutter UI + Kola Design System]
    App[Application / Use Cases]
    Domain[Kola-owned Domain Models]
    DB[(SQLite / Drift)]
    Files[(Local / Managed Files)]
    AdapterRegistry[FormatRegistry]
    FidelityRegistry[FidelityRendererRegistry]
    Engines[Format Engines]
    KDG[Kola Document Graph]
    Flow[Flow Mode]
    Search[Local Search]
    Ann[Annotations]
    Read[Progress / Coverage / Sessions]
    Sync[Optional BYOC Projection]

    OS --> Shell --> UI --> App --> Domain
    Domain <--> DB
    Domain --> AdapterRegistry --> Engines
    Domain --> FidelityRegistry --> Engines
    Engines --> Files
    Engines --> KDG
    KDG --> Flow
    KDG --> Search
    KDG --> Ann
    KDG --> Read
    DB -. optional .-> Sync
```

Local reading never depends on sync.

## 2. Import + identity

```mermaid
flowchart LR
    Pick[Native Picker]
    Source[Selected File]
    Detect[Signature + Container + Extension]
    Hash[Stream SHA-256]
    ID[sha256 Document ID]
    Mode{Import Mode}
    Managed[Managed Copy]
    Linked[Linked File]
    Registry[FormatRegistry]
    Meta[Adapter Metadata / Filename Fallback]
    Repo[DocumentRepository]
    DB[(SQLite)]
    Library[Reactive Library]

    Pick --> Source
    Source --> Detect
    Source --> Hash --> ID
    ID --> Mode
    Mode -- default --> Managed
    Mode -- explicit --> Linked
    Detect --> Registry --> Meta
    Managed --> Meta
    Linked --> Meta
    ID --> Repo
    Meta --> Repo --> DB --> Library
```

Rules: original files are untouched; identical bytes share identity; unknown formats do not mutate the library; managed copies are durable, not cache.

## 3. Current real PDF reader path

```mermaid
flowchart LR
    Route[reader/:documentId]
    Provider[documentProvider]
    Repo[DocumentRepository]
    Doc[KolaDocument]
    Cap[FormatRegistry]
    Renderers[FidelityRendererRegistry]
    Resolver[DocumentSourceResolver]
    PdfAdapter[PdfrxPdfAdapter]
    PdfView[PdfrxPdfFidelityRenderer]
    PDFium[pdfrx / PDFium]
    Pages[Real PDF Pages]

    Route --> Provider --> Repo --> Doc
    Doc --> Cap --> PdfAdapter
    Doc --> Renderers --> PdfView
    PdfView --> Resolver --> PDFium --> Pages
```

Important boundary:

```text
Generic Reader feature
  -> Kola registries/interfaces
  -> package-specific PDF adapter/renderer
  -> pdfrx/PDFium
```

Generic Reader code must not import `pdfrx`.

## 4. PDF capability state

```mermaid
flowchart TD
    PDF[PDF Adapter]
    Fidelity[Fidelity View ✅]
    Nav[Page navigation / zoom ✅]
    Flow[Flow Mode ❌]
    Search[Search ❌]
    Select[Text selection ❌]
    Annotate[Text annotations ❌]
    Outline[Outline UI ❌]

    PDF --> Fidelity --> Nav
    PDF -. future .-> Flow
    PDF -. future .-> Search
    PDF -. future .-> Select
    PDF -. future .-> Annotate
    PDF -. future .-> Outline
```

Capability flags describe integrated Kola behavior, not raw engine features.

## 5. Universal adapter contract

```mermaid
flowchart LR
    Doc[KolaDocument]
    Adapter[DocumentAdapter]
    Handle[DocumentHandle with stable documentId]
    Fidelity[Fidelity Descriptor]
    Extract[Semantic Extraction]
    Graph[KDG + Source Map]
    Index[Index Chunks]
    Resolve[Annotation Resolution]

    Doc --> Adapter --> Handle
    Handle --> Fidelity
    Handle --> Extract --> Graph
    Handle --> Index
    Handle --> Resolve
```

`DocumentAdapter.open()` receives `KolaDocument`, never only a file path, because handles must preserve stable content identity across file moves/renames.

## 6. Flow + annotation invariant

```mermaid
flowchart LR
    Source[Source Content]
    Block[KDG Block]
    Map[Source Mapping]
    Flow[Flow Block]
    Selection[Selection]
    Anchor[Hybrid Annotation Anchor]
    Back[Resolve to Source]

    Source --> Block --> Flow --> Selection --> Anchor
    Source --> Map --> Anchor --> Back --> Source
```

Never enable Flow/selection when annotatable content cannot resolve back to source reliably.

## 7. Persistence/data path

```mermaid
flowchart LR
    DB[(SQLite / Drift)]
    DocRepo[Document Repository]
    ReadRepo[Reading Repository]
    AnnRepo[Annotation Repository]
    Models[Kola Domain Models]
    Providers[Riverpod Providers]
    Home[Home]
    Library[Library]
    Insights[Insights]
    Reader[Reader]

    DB --> DocRepo --> Models
    DB --> ReadRepo --> Models
    DB --> AnnRepo --> Models
    Models --> Providers
    Providers --> Home
    Providers --> Library
    Providers --> Insights
    Providers --> Reader
```

Drift row types never escape the data layer. Raw datetime writes serialize to UTC ISO-8601 strings.

## 8. Reading state model

```mermaid
flowchart LR
    Events[Reader Events]
    Position[Position]
    Coverage[Actual Coverage]
    Session[Active Reading Session]
    DB[(SQLite)]

    Events --> Position --> DB
    Events --> Coverage --> DB
    Events --> Session --> DB
```

`position != coverage != active reading time`.

## 9. Adaptive-native UI policy

```mermaid
flowchart LR
    Platform[Platform]
    Window[Window Size]
    Input[Touch / Mouse / Keyboard / Stylus]
    A11y[Accessibility]
    Policy[Kola Adaptive Policy]
    UI[Native-feeling Presentation]

    Platform --> Policy
    Window --> Policy
    Input --> Policy
    A11y --> Policy
    Policy --> UI
```

Semantics stay consistent; navigation/chrome/menus/sheets/back/scrollbars/selection/density adapt to platform and capabilities.

## 10. Optional BYOC

```mermaid
flowchart LR
    DB[(Local SQLite)]
    Projection[Versioned Sync Records]
    Backend[User-selected SyncBackend]
    Cloud[(User Cloud / Folder)]

    DB -. optional .-> Projection -.-> Backend -.-> Cloud
```

Never sync the live SQLite file. Sync failures never block local reading.

## 11. Agent patch protocol

```mermaid
flowchart LR
    Task[Task]
    Read[AGENTS + STATE + GRAPH + one spec]
    Change[Implement]
    Test[Test / Analyze]
    State[Update PROJECT_STATE]
    Graph[Update GRAPH if architecture changed]
    Decision[Update DECISIONS if durable choice changed]
    Done[Done]

    Task --> Read --> Change --> Test --> State --> Graph --> Decision --> Done
```
