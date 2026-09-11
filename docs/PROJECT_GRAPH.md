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
    Intelligence[Reading Intelligence]
    DB[(SQLite / Drift)]
    Files[(Local Files)]
    Cache[(Disposable Caches)]
    SyncProjection[Optional Sync Projection]
    SyncBackend[User-selected SyncBackend]
    Cloud[(User's Cloud / Sync Folder)]

    OS --> Shell --> UI --> App --> Domain --> Registry --> Engines
    Engines --> ND
    Engines --> SM
    ND --> Fidelity
    ND --> Flow
    ND --> Search
    SM --> Ann
    ND --> Progress
    Progress --> Intelligence
    Ann --> DB
    Progress --> DB
    Intelligence --> DB
    Search --> DB
    Registry --> Files
    Fidelity --> Cache
    Flow --> Cache
    DB -. optional .-> SyncProjection -.-> SyncBackend -.-> Cloud
```

Local reading never depends on the sync path.

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

## 6. Reading Intelligence

### Active-time tracking

```mermaid
stateDiagram-v2
    [*] --> Inactive
    Inactive --> ActiveReading: reader visible + activity
    ActiveReading --> PassiveCandidate: no interaction, readable viewport remains
    PassiveCandidate --> ActiveReading: interaction resumes
    PassiveCandidate --> Idle: inactivity exceeds trusted dwell window
    ActiveReading --> Idle: app background / lock / hidden
    Idle --> ActiveReading: reading resumes
    Idle --> [*]
```

Only trusted reading states contribute to active reading time.

### Analytics pipeline

```mermaid
flowchart LR
    Reader[Reader Events]
    Tracker[ReadingActivityTracker]
    Sessions[Durable Reading Sessions]
    Coverage[Coverage Deltas]
    Insights[ReadingInsightsService]
    Goals[Goals]
    List[Reading List / Next Up]
    Dashboard[Reading Dashboard]
    DB[(SQLite / Drift)]

    Reader --> Tracker --> Sessions --> DB
    Reader --> Coverage --> DB
    Goals --> DB
    List --> DB
    DB --> Insights --> Dashboard
```

### Reading list states

```mermaid
flowchart LR
    Want[Want to Read]
    Next[Next Up]
    Reading[Reading]
    Paused[Paused]
    Done[Completed]
    Abandoned[Abandoned / Not for Me]

    Want --> Next --> Reading
    Reading --> Paused --> Reading
    Reading --> Done
    Reading --> Abandoned
    Paused --> Abandoned
```

Rules:

- Reading List is separate from Favorites.
- Streaks/goals are optional and secondary.
- Analytics stay local unless explicitly included in BYOC sync.
- Sync durable sessions/list/goals; derive chart aggregates locally.

Detailed design: `docs/READING_ANALYTICS.md`.

## 7. Adaptive-native UX policy

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

Stable semantics: Library, Search, Collections, Reading List, Insights, Reader, Fidelity View, Flow Mode, Focus Mode, annotations, progress, themes, optional Sync.

Adaptive presentation: navigation, window chrome, sheets/dialogs, menus, back behavior, scrollbars, selection UI, density, haptics, hover/right-click, shortcuts.

## 8. Theme model

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

## 9. Persistence boundaries

```mermaid
flowchart LR
    Source[User Source Documents]
    Durable[Durable Kola Data]
    Cache[Disposable Cache]

    Durable --> DB[(SQLite / Drift)]
    Durable --> A[Annotations]
    Durable --> P[Progress / Coverage]
    Durable --> R[Reading Sessions / Goals / Reading List]
    Durable --> C[Collections / Tags]
    Durable --> T[Settings / Themes]

    Cache --> Thumbs[Thumbnails]
    Cache --> Raster[Rendered Pages]
    Cache --> Reflow[Reflow Analysis]
    Cache --> Index[Rebuildable Index Data]
    Cache --> Analytics[Rebuildable Analytics Aggregates]
```

Clearing cache must never delete user-generated data or durable reading history.

### Current reactive application data path

```mermaid
flowchart LR
    DB[(SQLite / Drift)]
    DocRepo[DriftDocumentRepository]
    ReadRepo[DriftReadingRepository]
    AnnRepo[DriftAnnotationRepository]
    Domain[App-owned domain models]
    Providers[Riverpod query providers]
    Home[Home]
    Library[Library]
    Insights[Reading Insights]
    Reader[Reader / annotations later]

    DB --> DocRepo
    DB --> ReadRepo
    DB --> AnnRepo
    DocRepo --> Domain
    ReadRepo --> Domain
    AnnRepo --> Domain
    Domain --> Providers
    Providers --> Home
    Providers --> Library
    Providers --> Insights
    Providers -. document-specific state .-> Reader
```

Rules:

- Drift-generated row classes never escape the data layer.
- Repository writes explicitly invalidate affected Drift tables so streams refresh immediately.
- UI consumes Riverpod query providers, not SQL or generated database rows.
- Home, Library, and Insights now use durable local data; the Reader still waits for a real format adapter.

## 10. Bring Your Own Cloud sync

```mermaid
flowchart LR
    Mutation[Local Mutation]
    DB[(Local SQLite)]
    Journal[Sync Journal]
    Projection[Versioned Portable Records]
    Encrypt{Client-side encryption?}
    Cipher[Encrypted Records / Blobs]
    Plain[Plain Records / Blobs]
    Backend[SyncBackend]
    Remote[(User-controlled Cloud)]

    Mutation --> DB --> Journal --> Projection --> Encrypt
    Encrypt -- yes --> Cipher --> Backend
    Encrypt -- no --> Plain --> Backend
    Backend --> Remote
```

Pull/merge path:

```mermaid
flowchart LR
    Remote[(User Cloud)]
    Backend[SyncBackend]
    Download[Changed Records]
    Verify[Decrypt / Verify / Validate]
    Merge[Conflict-aware Merge]
    Tx[Local DB Transaction]
    DB[(SQLite)]

    Remote --> Backend --> Download --> Verify --> Merge --> Tx --> DB
```

### Sync backend families

```mermaid
flowchart TB
    S[SyncBackend]
    S --> Folder[Local Sync Folder]
    S --> WebDAV[WebDAV]
    S --> Drive[Google Drive]
    S --> OneDrive[OneDrive]
    S --> Dropbox[Dropbox]
    S --> S3[S3-compatible]
```

**Rules:** never sync the live SQLite file; sync is optional; local reading continues through all sync failures.

## 11. Evidence-based UX loop

```mermaid
flowchart TD
    Problem[Observed User / Reading Problem]
    Context[Define User + Task + Platform + Context]
    Hypothesis[Design Hypothesis]
    Evidence{Best available basis?}
    Standards[Accessibility / Standards]
    Research[HCI / Human Factors]
    Convention[Platform Convention]
    Experiment[Explicit Design Experiment]
    Prototype[Prototype Competing Solution]
    Test[User Test / Reading Session]
    Behavior[Behavioral Metrics]
    Experience[UX / Aesthetic Measures]
    Decide{Success criteria met?}
    Keep[Keep + Document]
    Revise[Revise / Reject]

    Problem --> Context --> Hypothesis --> Evidence
    Evidence --> Standards
    Evidence --> Research
    Evidence --> Convention
    Evidence --> Experiment
    Standards --> Prototype
    Research --> Prototype
    Convention --> Prototype
    Experiment --> Prototype
    Prototype --> Test
    Test --> Behavior
    Test --> Experience
    Behavior --> Decide
    Experience --> Decide
    Decide -- yes --> Keep
    Decide -- no --> Revise --> Hypothesis
```

### UX evidence priority

```text
Accessibility/standards
  > validated human-factors evidence
  > native platform convention
  > measured Kola user results
  > visual trend / deliberate experiment
```

Trends are permitted only when they do not undermine the layers above.

Core visual thesis:

```text
Calm reading surface
+ familiar structure
+ high craftsmanship
+ selective expressive interactions
+ platform-native behavior
```

Detailed rationale: `docs/UX_RESEARCH.md`.
Testing protocol: `docs/UX_VALIDATION.md`.

## 12. Agent change protocol

```mermaid
flowchart TD
    Task[Task Received]
    Read[Read AGENTS + PROJECT_STATE + PROJECT_GRAPH]
    Spec[Read One Relevant Detailed Spec]
    Change[Implement Change]
    Test[Test / Analyze]
    State[Update PROJECT_STATE]
    Arch{Architecture/data flow changed?}
    UX{Meaningful UX pattern changed?}
    Decision{Durable decision changed?}
    Req{Requirement changed?}
    Graph[Update PROJECT_GRAPH]
    Validate[Check UX_RESEARCH / UX_VALIDATION]
    ADR[Update DECISIONS]
    Detail[Update Relevant Spec]
    Done[Patch Complete]

    Task --> Read --> Spec --> Change --> Test --> State --> Arch
    Arch -- yes --> Graph --> UX
    Arch -- no --> UX
    UX -- yes --> Validate --> Decision
    UX -- no --> Decision
    Decision -- yes --> ADR --> Req
    Decision -- no --> Req
    Req -- yes --> Detail --> Done
    Req -- no --> Done
```

A patch is not complete until this context is synchronized.
