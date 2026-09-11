# Kola — Product Specification

> A private, local-first, cross-platform universal reader and annotation workspace for books, documents, presentations, spreadsheets, papers, comics, and other readable files.

## 1. Product vision

Kola should make digital reading calmer, faster, more flexible, attractive, and more private than conventional document viewers while remaining completely usable without an account, subscription, cloud service, or internet connection.

Kola is not merely a PDF or ebook reader. It is a **universal local reading workspace** in which supported files can be opened, searched, highlighted, annotated, tracked, personalized, synchronized optionally, and exported through one coherent interaction model.

### Product promise

- One application for major ebook, document, presentation, spreadsheet, comic, text, and fixed-layout formats.
- One Flutter application codebase for Linux, Windows, macOS, Android, and iOS.
- Local-first and fully functional offline.
- Optional **Bring Your Own Cloud (BYOC)** sync without requiring Kola-hosted storage.
- No mandatory account.
- No mandatory telemetry.
- No document uploads for core features; document sync is explicit opt-in.
- Unified annotations across formats.
- Universal source-linked Flow Mode where semantic extraction is possible.
- Reading progress, actual coverage, active reading time, completion history, and Reading List tracking.
- Deep control over app themes, reader themes, backgrounds, typography, spacing, and document surfaces.
- First-class keyboard, mouse, touch, and stylus workflows.
- User-owned annotations, backups, exports, analytics, and sync targets.
- No AI assistant subsystem and no dedicated study-system subsystem.

## 2. Product principles

### 2.1 Reading first

The file being read is always the visual focus. Panels and controls disappear when they are not useful.

### 2.2 Local-first, not merely offline-capable

Kola stores its library, metadata, reading progress, coverage history, reading sessions, annotations, bookmarks, Reading List, custom themes, thumbnails, caches, and indexes locally.

Cloud synchronization is optional transport. Local state remains usable and writable before, during, and after sync failures.

### 2.3 One document model, multiple views

A document may expose a fidelity/source view and one or more reading views, but they all point to the same document identity.

Examples:

- PDF: page view + Flow Mode
- EPUB: book layout + Flow Mode
- DOCX: document layout + Flow Mode
- PPTX: slide view + Flow Mode
- XLSX: sheet view + Flow Mode
- comic: page view + optional OCR/reading flow

Annotations must remain tied to the original source location whenever technically possible.

### 2.4 Universal Flow Mode

Flow Mode is a product-wide capability, not a PDF feature.

Every adapter produces or attempts to produce a source-mapped semantic representation of the document. Flow Mode renders that representation using the user's preferred typography and reader theme.

### 2.5 Honest degradation

Kola should support broad formats without pretending all files are equally structured.

If a document cannot be perfectly reconstructed, Kola should:

1. keep the original/fidelity view available;
2. expose the best safe Flow Mode it can produce;
3. preserve source visual blocks where semantic conversion would lose meaning;
4. show that the Flow representation is approximate when appropriate.

### 2.6 User ownership

The source file remains untouched unless the user explicitly exports a modified copy. Kola's local database and sidecars hold app state and annotations.

If sync is enabled, the user chooses the provider, remote location, sync scope, and whether document binaries leave the device.

### 2.7 Focused product scope

Kola deepens the reading experience instead of expanding into unrelated product categories.

The following are not part of the committed product scope:

- AI chat, BYO AI, local LLM, document Q&A, AI summaries, or other AI-assistant features;
- flashcards or spaced repetition;
- mind maps or concept boards;
- knowledge graphs/backlinks as a study system;
- Recall Mode, study decks, quizzes, or dedicated study sheets;
- public social-network features;
- proprietary ebook store.

Ordinary notes, annotations, tags, collections, local search, Reading Intelligence, exports, TTS, lookup, translation, and document comparison remain reader features.

## 3. Format strategy

Kola's long-term target is **market-complete support for practical unencrypted readable formats** where maintainable local parsing/rendering is possible.

Detailed strategy: [`UNIVERSAL_FORMATS.md`](UNIVERSAL_FORMATS.md).

### Major ebook targets

- EPUB 2/3
- KEPUB
- MOBI
- AZW / AZW3 / compatible unencrypted Kindle containers
- FB2 / FBZ
- PRC
- PDB
- PML / PMLZ
- LIT
- LRF
- RB
- SNB
- TCR
- CHM
- HTML / HTMLZ
- OEB/OPF packages
- TXT / TXTZ
- RTF
- PDF
- DjVu
- DAISY/DTBook where practical

### Office and productivity documents

- DOCX / DOC
- ODT
- RTF
- PPTX / PPT
- ODP
- XLSX / XLSM / XLSB / XLS
- ODS / FODS
- CSV / TSV
- Pages / Keynote / Numbers when maintainable local parsing is available

### Comics and visual publications

- CBZ
- CBR
- CB7
- CBC
- image folders

### Additional fixed-layout/text targets

- XPS / OXPS
- Markdown
- HTML/XHTML
- XML where meaningful structure can be inferred
- reStructuredText
- AsciiDoc

### DRM policy

Kola does not bypass DRM. A supported container is readable only when Kola can legally and technically decode it locally.

## 4. Core reader modes

### 4.1 Fidelity View

The closest practical representation of the source file.

Examples:

- PDF pages
- slide canvas
- spreadsheet grid
- comic pages
- word-processing layout

### 4.2 Flow Mode

A universal source-mapped semantic reading view.

Flow Mode should support:

- headings;
- paragraphs;
- lists;
- quotes;
- links;
- footnotes/endnotes;
- tables;
- figures/images;
- captions;
- code blocks;
- slide titles and speaker notes;
- spreadsheet tables/regions/cells;
- OCR-derived blocks;
- source-preserving blocks for content that should not be flattened.

User controls:

- font family;
- text size;
- line height;
- paragraph spacing;
- content width;
- margins;
- alignment where appropriate;
- column count where appropriate;
- hyphenation toggle;
- reader theme;
- text color;
- background color;
- page/surface color;
- ambient background.

**Non-negotiable rule:** Flow Mode is never an unrelated converted copy. Every annotatable block retains a source locator when one can be established.

### 4.3 Focus Mode

A distraction-free mode that removes almost all application chrome while preserving progress and annotation controls on demand.

### 4.4 Comic / Visual Mode

- single page;
- double page;
- right-to-left;
- fit width/height;
- smart panel zoom later;
- optional OCR Flow Mode for text-heavy scanned pages.

### 4.5 Presentation Mode

- slide navigator;
- fullscreen slide reading;
- notes toggle;
- slide annotation layer;
- Flow Mode for linearized presentation content.

### 4.6 Sheet Mode

- sheet tabs;
- frozen headers where parsed;
- zoomable/virtualized grid;
- cell/range comments and annotations;
- search;
- Flow Mode for accessible table traversal.

### 4.7 Parallel Read / Compare

Two reading surfaces may appear side by side for:

- original + translation;
- two document versions;
- two books/papers/documents;
- presentation + reference material.

Navigation can be independent or synchronized where meaningful.

## 5. Reading progress, time, and completion

Kola distinguishes **where the user is**, **how much has actually been read**, and **how much trusted active time was spent reading**.

### Position progress

Examples:

- `63%`
- `Page 188 of 300`
- `Chapter 14 of 22`
- `Slide 31 of 64`
- `Sheet 3 of 8`

### Reading coverage

A separate metric records semantic content that genuinely entered the reading viewport for a meaningful interval.

```text
Current position: 63%
Read coverage:    48%
```

Jumping to the end must not mark the whole document as read.

### Active reading time

Reading time is based on meaningful reading activity, not merely how long a document window remains open.

Users must be able to inspect, correct, and delete erroneous sessions.

### Completion state

Documents can be:

- Unread
- Started
- In progress
- Nearly finished
- Completed
- Manually marked complete
- optional Abandoned / DNF

### Reading Intelligence

Local-only analytics may include:

- total active reading time;
- session duration/count;
- average/longest session;
- pages/chapters/slides/semantic units covered;
- daily/weekly/monthly/yearly history;
- progress over time;
- first/last read date;
- completion history;
- estimated time remaining where confidence is sufficient;
- annotation counts;
- Reading List / Want to Read / Next Up.

Statistics remain local unless the user explicitly includes them in BYOC state sync.

Detailed design: `READING_ANALYTICS.md`.

## 6. Annotation system

Annotations are a first-class domain shared across formats.

### Types

- Highlight
- Underline
- Strikeout
- Text note
- Margin note
- Freehand ink
- Shape
- Arrow
- Bookmark
- Image/area selection
- Cell/range annotation
- Slide-region annotation
- Text box

### Semantic highlight presets

- Important
- Definition
- Evidence / Example
- Question
- Idea / Connection
- Review

The semantic label is stored independently from its visible color.

### Source anchors

Annotations should store a hybrid anchor containing structural location, exact text/context, geometry/range information, and fallback selectors.

This allows the same annotation to survive changes in zoom, screen size, theme, Flow Mode, and typography.

## 7. Themes, backgrounds, and visual personalization

Application chrome and document appearance are separate systems.

### Application themes

Built-ins may include:

- System
- Light
- Dark
- OLED Black
- Soft Gray
- Warm Neutral

Users can create custom themes controlling:

- accent color;
- navigation/background color;
- panel surfaces;
- border strength;
- contrast level;
- corner/radius scale;
- reduced-transparency preference.

### Reader themes

Built-ins may include:

- Paper
- Warm Paper
- Sepia
- Soft Gray
- Sage
- Night
- Low-Contrast Night
- OLED Black

Custom reader themes can control:

- text color;
- link color;
- selection color;
- highlight remapping;
- document background;
- page background;
- margins;
- subtle texture.

### Ambient backgrounds

The area around the document/page can use:

- solid color;
- gradient;
- subtle texture;
- user-selected local image/wallpaper;
- blurred local image background.

Kola must preserve minimum text contrast and provide a one-click reset if customization becomes unreadable.

## 8. Library experience

Library views may include:

- Home / Continue Reading
- All Documents
- Recent
- Favorites
- Collections
- Tags
- Annotated
- Unread
- In Progress
- Completed
- Want to Read
- Next Up

Cards/list rows may show:

- cover/thumbnail;
- title;
- author;
- format;
- position progress;
- reading coverage;
- time spent reading;
- last opened/read;
- completion state;
- local/cloud availability when BYOC is configured.

## 9. Universal local search

Local search covers:

- title;
- author;
- metadata;
- body text;
- annotations;
- notes;
- tags;
- slide text;
- spreadsheet cells;
- speaker notes;
- OCR content.

Search results must jump to a resolvable source location.

Search remains classic local full-text/indexed search; no AI/embedding subsystem is part of the committed product.

## 10. Signature reader interactions

### Peek

Preview footnotes, citations, internal links, slide references, figures, tables, and other source references without losing reading position.

### Reading Lens

A movable line/paragraph focus tool for dense content and accessibility.

### Annotation Rail

Nonintrusive edge markers show where notes/highlights exist without opening a side panel.

### Command Palette

`Ctrl/Cmd + K` on desktop/tablet for search, navigation, view switching, themes, annotation tools, sync actions, and export.

### Read Aloud

Use local/platform TTS first, with synchronized source position, speed/voice controls, and background playback where permitted.

### Lookup / translation

Selection can expose dictionary, optional reference lookup, and optional translation without requiring an always-online reader.

## 11. Bring Your Own Cloud sync

Kola may synchronize across devices using storage the user controls.

Detailed architecture: [`SYNC.md`](SYNC.md).

### Backend direction

- local sync folder;
- WebDAV;
- Google Drive;
- Microsoft OneDrive;
- Dropbox;
- S3-compatible storage.

Provider integrations are adapters. Kola's reading/domain code must not depend directly on a provider.

### Sync scopes

Users choose one:

- **State only:** annotations, bookmarks, progress/coverage, reading sessions/history, Reading List, collections, tags, themes, metadata, and selected settings.
- **Selected documents:** state plus explicitly chosen documents.
- **Full library:** state plus all eligible managed documents.

State-only is the privacy- and bandwidth-friendly default direction.

### Sync behavior

- local changes are committed immediately;
- sync runs in the background;
- offline edits are allowed;
- sync conflicts never block reading;
- conflicting user-authored notes are preserved rather than silently discarded;
- reading coverage merges across compatible graph versions;
- deletions use tombstones;
- document blobs use content hashes for stable identity/deduplication.

### Sync privacy

Kola should support optional client-side encrypted sync vaults so third-party storage can hold ciphertext instead of plaintext Kola records/documents.

No cloud connection is made until the user explicitly configures a Sync Vault.

## 12. Security and privacy

Core local reading performs **zero network requests**.

Rules:

- no mandatory account;
- no mandatory Kola cloud/database;
- no ads;
- no remote fonts required;
- no document upload unless the user explicitly enables document sync;
- no AI/LLM assistant subsystem;
- no Office macro execution;
- no embedded JavaScript execution by default;
- external resources from documents blocked by default;
- all search indexes/thumbnails remain local;
- OAuth/provider credentials stored through OS secure storage, not plaintext app data;
- disconnected sync must leave all local user data intact.

## 13. Accessibility

Kola should support:

- complete keyboard navigation;
- screen-reader semantics;
- visible focus;
- reduced motion;
- large text;
- high-contrast themes;
- non-color annotation labels;
- RTL documents;
- dyslexia-friendly typography options;
- Flow Mode as an accessibility representation for fixed-layout files;
- local text-to-speech.

## 14. Performance expectations

- opening a file must not wait for full indexing or sync;
- parsing, indexing, and sync happen off the UI isolate/critical reader path;
- large files use bounded caches;
- reader interaction targets 60 fps or device refresh rate where practical;
- huge libraries remain metadata-responsive;
- already parsed documents reuse versioned caches;
- spreadsheet/grid rendering virtualizes rows/columns;
- presentation thumbnails render lazily;
- Flow Mode can build progressively instead of blocking the whole document;
- document synchronization supports resumable/background transfer where provider/platform capabilities permit it;
- reading-session tracking adds negligible UI overhead.

## 15. Non-goals

- no AI assistants, LLM integrations, BYO AI, AI summaries, or AI document chat;
- no flashcards, spaced repetition, study decks, mind maps, knowledge graph/backlinks system, Recall Mode, or quiz system;
- no cloud dependency;
- no mandatory sync;
- no mandatory Kola-hosted cloud;
- no DRM bypass;
- no Word/Excel/PowerPoint-class source editing suite;
- no active macro/script execution;
- no requirement that every format have pixel-perfect layout fidelity before it can be read;
- no public social network as a core product feature;
- no multi-user collaborative document editing in the initial product direction.

## 16. Definition of success

Kola succeeds when a user can install one application on desktop or mobile, open almost any common unencrypted readable file, switch between its original representation and a comfortable Flow Mode, annotate it consistently, search it locally, understand real reading progress/time, customize the reading environment deeply, and later resume with all state intact—without sending the document anywhere.

For users who opt into BYOC, Kola additionally succeeds when they can connect their own storage on multiple devices and have progress, annotations, reading history, Reading List, and chosen documents converge safely without requiring infrastructure controlled by Kola.
