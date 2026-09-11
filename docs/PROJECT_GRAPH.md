# Kola — Project Graph

Compact visual context for agents. Read with `AGENTS.md` and `docs/PROJECT_STATE.md` before opening long-form specs.

## 1. System architecture

```mermaid
flowchart TD
    OS[Platform: Linux / Windows / macOS / Android / iOS]
    Shell[Adaptive Native Shell]
    UI[Flutter UI + Kola Design System]
    App[Application / Use Cases]
    Domain[Kola Domain]
    Registry[DocumentAdapter Registry]
    Engines[Format Engines / Parsers]
    ND[NormalizedDocument]
    SM[SourceMap]
    Fidelity[Fidelity View]
    Flow[Flow Mode]
    Search[Local Search]
    Ann[Annotations]
    Progress[Progress + Coverage]
    DB[(SQLite / Drift)]
    Files[(Local Files)]
    Cache[(Disposable Caches)]

    OS --> Shell --> UI --> App --> Domain --> Registry --> Engines
    Engines --> ND
    Engines --> SM
    ND --> Fidelity
    ND --> Flow
    ND --> Search
    SM --> Ann
    ND --> Progress
    Ann --> DB
    Progress --> DB
    Search --> DB
    Registry --> Files
    Fidelity --> Cache
    Flow --> Cache
```

## 2. Universal document pipeline

```mermaid
flowchart LR
    Source[Source File]
    Detect[Detect Format]
    Adapter[DocumentAdapter]
    Meta[Metadata]
    Fidelity[Fidelity Renderer]
    Extract[Extract Structure / Content]
    Normalize[Normalize Blocks]
    Map[Build SourceMap]
    Index[Search Index]
    Flow[Flow Renderer]
    Anchor[Annotation Resolver]

    Source --> Detect --> Adapter
    Adapter --> Meta
    Adapter --> Fidelity
    Adapter --> Extract --> Normalize
    Normalize --> Map
    Normalize --> Index
    Normalize --> Flow
    Map --> Anchor
```

### Adapter families

```mermaid
flowchart TB
    R[DocumentAdapter Registry]
    R --> PDF[PDF / DjVu / fixed layout]
    R --> EPUB[EPUB / ebook containers]
    R --> TEXT[TXT / Markdown / HTML]
    R --> WORD[DOCX / word-processing]
    R --> SLIDE[PPT / PPTX / presentations]
    R --> SHEET[XLS / XLSX / spreadsheets]
    R --> COMIC[CBZ / CBR / image sequences]
    R --> SCAN[Images / scanned documents]
```

## 3. Flow Mode invariant

```mermaid
flowchart LR
    S[Source Content]
    B[Normalized Block]
    M[Source Mapping]
    F[Flow Block]
    Sel[User Selection]
    A[Annotation]
    Back[Resolve Back to Source]

    S --> B
    S --> M
    B --> F --> Sel --> A
    M --> A
    A --> Back --> S
```

**Rule:** no Flow block containing annotatable content may become detached from its source mapping.

## 4. Annotation anchor resolution

```mermaid
flowchart TD
    A[AnnotationAnchor]
    L{Source locator valid?}
    Q{Exact quote verifies?}
    O{Logical offsets valid?}
    C{Quote + context match?}
    R[Resolved]
    U[Unresolved / repair state]

    A --> L
    L -- yes --> Q
    L -- no --> O
    Q -- yes --> R
    Q -- no --> O
    O -- yes --> R
    O -- no --> C
    C -- yes --> R
    C -- no --> U
```

Never silently attach an annotation to a different passage.

## 5. Reading progress

```mermaid
flowchart LR
    Events[Reader Visibility / Navigation Events]
    Pos[Position Progress]
    Coverage[Reading Coverage]
    Session[Reading Session]
    State[Reading State]
    DB[(SQLite)]

    Events --> Pos
    Events --> Coverage
    Events --> Session
    Pos --> State
    Coverage --> State
    Session --> State
    State --> DB
```

`Position Progress != Reading Coverage`.

## 6. Adaptive-native UX policy

```mermaid
flowchart TD
    Platform[Host Platform]
    Window[Available Window Size]
    Input[Mouse / Keyboard / Touch / Stylus]
    A11y[Accessibility / Motion / Text Scale]
    Policy[Kola Adaptive UI Policy]
    Semantics[Stable Kola Semantics]
    Presentation[Native Presentation]

    Platform --> Policy
    Window --> Policy
    Input --> Policy
    A11y --> Policy
    Semantics --> Policy
    Policy --> Presentation
```

Stable semantics: Library, Search, Collections, Reader, Fidelity View, Flow Mode, Focus Mode, annotations, progress, themes.

Adaptive presentation: navigation, window chrome, sheets/dialogs, menus, back behavior, scrollbars, selection UI, density, haptics, hover/right-click, shortcuts.

## 7. Theme model

```mermaid
flowchart TD
    Settings[Theme Settings]
    AppTheme[Application Chrome Theme]
    ReaderTheme[Reader Theme]
    Background[Document Background]
    Text[Reader Text / Contrast]

    Settings --> AppTheme
    Settings --> ReaderTheme
    ReaderTheme --> Background
    ReaderTheme --> Text
```

App chrome and reader surface themes are intentionally independent.

## 8. Persistence boundaries

```mermaid
flowchart LR
    Source[User Source Documents]
    Durable[Durable Kola Data]
    Cache[Disposable Cache]

    Durable --> DB[(SQLite / Drift)]
    Durable --> A[Annotations]
    Durable --> P[Progress / Coverage]
    Durable --> C[Collections / Tags]
    Durable --> T[Settings / Themes]

    Cache --> Thumbs[Thumbnails]
    Cache --> Raster[Rendered Pages]
    Cache --> Reflow[Reflow Analysis]
    Cache --> Index[Rebuildable Index Data]
```

Clearing cache must never delete user-generated data.

## 9. Agent change protocol

```mermaid
flowchart TD
    Task[Task Received]
    Read[Read AGENTS + PROJECT_STATE + PROJECT_GRAPH]
    Spec[Read One Relevant Detailed Spec]
    Change[Implement Change]
    Test[Test / Analyze]
    State[Update PROJECT_STATE]
    Arch{Architecture/data flow changed?}
    Decision{Durable decision changed?}
    Req{Requirement changed?}
    Graph[Update PROJECT_GRAPH]
    ADR[Update DECISIONS]
    Detail[Update Relevant Spec]
    Done[Patch Complete]

    Task --> Read --> Spec --> Change --> Test --> State --> Arch
    Arch -- yes --> Graph --> Decision
    Arch -- no --> Decision
    Decision -- yes --> ADR --> Req
    Decision -- no --> Req
    Req -- yes --> Detail --> Done
    Req -- no --> Done
```

A patch is not complete until this context is synchronized.
