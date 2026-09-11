# Kola — Product Specification

> A private, local-first, cross-platform universal reader and annotation workspace for books, documents, presentations, spreadsheets, papers, comics, and other readable files.

## 1. Product vision

Kola should make digital reading calmer, faster, more flexible, and more private than conventional document viewers while remaining completely usable without an account, subscription, cloud service, or internet connection.

Kola is not merely a PDF or ebook reader. It is a **universal local reading workspace** in which supported files can be opened, searched, highlighted, annotated, reviewed, tracked, and exported through one consistent interaction model.

### Product promise

- One application for major ebook, document, presentation, spreadsheet, comic, text, and fixed-layout formats.
- One Flutter application codebase for Linux, Windows, macOS, Android, and iOS.
- Local-only by default and fully functional offline.
- Optional **Bring Your Own Cloud (BYOC)** sync across devices without requiring Kola-hosted storage.
- No mandatory account.
- No mandatory telemetry.
- No document uploads for core features; document sync is explicit opt-in.
- Unified annotations across formats.
- Universal Flow Mode for every readable document where semantic extraction is possible.
- Reading progress, completion, and actual coverage tracking.
- Deep control over app themes, reader themes, backgrounds, typography, spacing, and page surfaces.
- First-class keyboard, mouse, touch, and stylus workflows.
- User-owned annotations, backups, exports, and sync targets.

## 2. Product principles

### 2.1 Reading first

The file being read is always the visual focus. Panels and controls should disappear when not useful.

### 2.2 Local-first, not merely offline-capable

Kola stores its library, metadata, reading progress, coverage history, annotations, bookmarks, custom themes, thumbnails, caches, and indexes locally.

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

Annotations must remain tied to the original source location whenever that mapping is technically possible.

### 2.4 Universal Flow Mode

Flow Mode is a product-wide capability, not a PDF feature.

Every adapter produces or attempts to produce a source-mapped semantic representation of the document. Flow Mode renders that representation using the user's preferred typography and reading theme.

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

## 3. Format strategy

Kola's long-term target is **market-complete support for unencrypted readable formats**.

The detailed capability strategy lives in [`UNIVERSAL_FORMATS.md`](UNIVERSAL_FORMATS.md).

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
- DAISY/DTBook as an accessibility expansion

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

Kola does not bypass DRM. A supported container is readable only when Kola can legally and technically decode the file locally.

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

**Non-negotiable rule:** Flow Mode is never an unrelated converted copy. Every block retains a source locator when one can be established.

### 4.3 Focus Mode

A distraction-free mode that removes almost all application chrome while preserving progress and annotation controls on demand.

### 4.4 Comic/Visual Mode

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

- tabs for sheets;
- frozen header support where parsed;
- zoomable grid;
- cell/range comments;
- search;
- range highlighting/annotations;
- Flow Mode for accessible table traversal.

## 5. Reading progress and completion

Kola should distinguish **where the user is** from **how much the user has actually read**.

### Position progress

Shows the current canonical position in the document:

- `63%`
- `Page 188 of 300`
- `Chapter 14 of 22`
- `Slide 31 of 64`
- `Sheet 3 of 8`

### Reading coverage

A second metric records content that has genuinely entered the reading viewport for a meaningful interval.

Example:

```text
Current position: 63%
Read coverage:    48%
```

This avoids marking a book as nearly complete merely because the user jumped to its last page.

### Completion state

Documents can be:

- Unread
- Started
- In progress
- Nearly finished
- Completed
- Manually marked complete

Default automatic completion can use a configurable threshold such as 95% coverage.

### Reading statistics

Local-only statistics may include:

- total reading time;
- session duration;
- pages/chapters/slides covered;
- daily/weekly reading history;
- progress over time;
- last read date.

Statistics remain local unless the user explicitly includes them in BYOC state sync.

## 6. Annotation system

Annotations are a first-class domain shared across all formats.

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
- Link between annotations

### Semantic highlight presets

- Important
- Definition
- Evidence / Example
- Question
- Idea / Connection
- Review

The semantic label is stored independently of its visible color.

### Source anchors

Annotations should store a hybrid anchor containing structural location, exact text/context, geometry/range information, and fallback selectors.

This allows the same annotation to survive changes in zoom, screen size, theme, Flow Mode, and typography.

## 7. Themes, backgrounds, and visual personalization

Application chrome and document appearance are separate systems.

### Application themes

Built-ins:

- System
- Light
- Dark
- OLED Black
- Soft Gray
- Warm Neutral

Users can create custom themes with:

- accent color;
- navigation/background color;
- panel surfaces;
- border strength;
- contrast level;
- corner/radius scale;
- optional reduced-transparency mode.

### Reader themes

Built-ins:

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
- optional subtle texture.

### Ambient backgrounds

The area around the document/page can use:

- solid color;
- gradient;
- subtle texture;
- user-selected local image/wallpaper;
- blurred local image background.

Kola must maintain minimum text contrast and provide a one-click reset if customization becomes unreadable.

## 8. Library experience

Library views:

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

Cards/list rows may show:

- cover/thumbnail;
- title;
- author;
- format;
- position progress;
- reading coverage;
- last opened;
- completion state;
- local/cloud availability when BYOC is configured.

## 9. Search and knowledge workflows

All local search should cover:

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

## 10. Signature interactions

### Peek

Preview footnotes, citations, internal links, slide references, figures, tables, and annotation links without losing reading position.

### Reading Lens

A movable line/paragraph focus tool for dense content and accessibility.

### Annotation Rail

Nonintrusive edge markers show where notes/highlights exist without opening a side panel.

### Command Palette

`Ctrl/Cmd + K` on desktop/tablet for search, navigation, view switching, theme changes, annotation tools, sync actions, and export.

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

- **State only:** annotations, bookmarks, progress/coverage, collections, tags, themes, metadata, and selected settings.
- **Selected documents:** state plus explicitly chosen documents.
- **Full library:** state plus all eligible managed documents.

State-only is the privacy- and bandwidth-friendly default direction.

### Sync behavior

- local changes are committed immediately;
- sync runs in the background;
- offline edits are allowed;
- sync conflicts never block reading;
- user-authored conflicting notes are preserved rather than silently discarded;
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
- no external AI API requirement;
- no Office macro execution;
- no embedded JavaScript execution by default;
- external resources from documents blocked by default;
- all search indexes/thumbnails remain local;
- OAuth/provider credentials are stored using OS secure storage, not plaintext app data;
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
- local text-to-speech in a later phase.

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
- document blob synchronization supports resumable/background transfer where backend/platform capabilities permit it.

## 15. Non-goals

- no cloud dependency;
- no mandatory sync;
- no mandatory Kola-hosted cloud;
- no DRM bypass;
- no Word/Excel/PowerPoint-class source editing suite;
- no active macro/script execution;
- no requirement that every file format have pixel-perfect layout fidelity before it can be read;
- no multi-user collaborative document editing in the initial BYOC design.

## 16. Definition of success

Kola succeeds when a user can install one application on desktop or mobile, open almost any common unencrypted reading/document file, switch between its original representation and a comfortable Flow Mode, annotate it consistently, track genuine reading progress, search it locally, customize the reading environment deeply, close the app, and later resume with all state intact—without sending the document anywhere.

For users who opt into BYOC, Kola additionally succeeds when those users can connect their own storage on multiple devices and have progress, annotations, and chosen documents converge safely without requiring infrastructure controlled by Kola.
