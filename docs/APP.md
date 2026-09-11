# Kola — Product Specification

> A private, local-first, cross-platform reading and annotation application for serious readers, students, researchers, and anyone who works deeply with documents.

## 1. Product vision

Kola should make reading digital documents feel calmer, faster, and more tactile than existing PDF/ebook readers while remaining completely usable without an account, subscription, server, or internet connection.

The product is not merely a PDF viewer. It is a **unified reading workspace** in which every supported document can be read, searched, highlighted, annotated, linked, reviewed, and exported through one consistent model.

### Product promise

- One app for PDF, EPUB, CBZ/CBR, Markdown, text, HTML and later DOCX/DjVu.
- One codebase for Linux, Windows, macOS, Android and iOS.
- Local-only by default and fully functional offline.
- No mandatory account.
- No telemetry by default.
- Fast startup and smooth reading even with large books.
- First-class keyboard, mouse, touch and stylus workflows.
- Annotations remain portable and exportable.
- Reading UI disappears when it is not needed.

## 2. Product principles

### 2.1 Reading first

The document is always the visual focus. Chrome, panels and toolbars should collapse or fade away whenever they are not actively useful.

### 2.2 Local-first, not offline-capable

Kola stores its library, metadata, reading progress, annotations, bookmarks and search index locally. Networking is not part of the core architecture.

### 2.3 The user's files remain the source of truth

Kola must never trap a user's work. Annotations are stored safely in Kola's database for speed and consistency, while users can export annotated PDFs, Markdown notes, JSON backups, or sidecar annotation bundles.

### 2.4 One document model, multiple views

A PDF may be viewed as original pages, continuous pages, two-page spread, focus crop, or reflowed Reading Mode. These are views of the same source document—not separate copies.

Annotations created in one compatible view must resolve to the same source location in the others.

### 2.5 Progressive power

A first-time user should be able to open a book and read immediately. Advanced capabilities should reveal themselves through selection actions, contextual menus, keyboard shortcuts, command palette and optional panels.

## 3. Primary user journeys

### Reader

1. Open or import a book.
2. Resume exactly where reading stopped.
3. Choose page or reflow mode.
4. Adjust typography, theme and margins.
5. Highlight interesting passages.
6. Add a note without leaving the page.
7. Search within the book.
8. Return later with all state preserved.

### Student

1. Import course PDFs and EPUB textbooks.
2. Organize them into collections.
3. Highlight using semantic colors such as Important, Definition, Question and Example.
4. Write margin notes or ink with a stylus.
5. See all annotations in a side panel.
6. Filter highlights by color/tag/chapter.
7. Export a study sheet as Markdown.

### Researcher

1. Open several papers in tabs.
2. Search all locally indexed documents.
3. Copy a quotation with page/source metadata.
4. Add tags and comments to highlights.
5. Jump from annotation back to exact source context.
6. Export an annotated PDF or structured notes.

## 4. Supported formats

### Tier 1 — v1

- PDF
- EPUB 2/3
- TXT
- Markdown
- HTML saved locally
- CBZ

### Tier 2

- CBR
- DOCX read-only/reflowed
- DjVu
- image folders

### Tier 3 / exploratory

- MOBI/AZW where legally and technically practical
- PowerPoint/ODP reading
- scanned document packages

Encrypted/DRM-protected ebook formats are explicitly outside the initial scope.

## 5. Core reader modes

### 5.1 Page Mode

Faithful source rendering.

Layouts:

- Continuous vertical
- Single page
- Two-page spread
- Right-to-left spread for manga/books
- Horizontal paging
- Fit width
- Fit page
- Actual size
- Custom zoom

### 5.2 Flow Mode

Kola's reflow experience for PDFs and inherently reflowable formats.

Flow Mode should:

- reconstruct reading order from text blocks;
- remove repetitive headers/footers when confidently detected;
- collapse multi-column layouts into a readable sequence;
- preserve headings, paragraphs, lists and quotations;
- keep figures/tables near their source context;
- offer font family, text size, line height, paragraph spacing, column width and margins;
- support light, dark, sepia and custom reading themes;
- maintain the same reading position when toggling back to source pages;
- allow highlights, underlines and notes directly in Flow Mode;
- map those annotations back to the original source page and geometry.

**Non-negotiable rule:** Flow Mode is never a disconnected text copy.

### 5.3 Focus Mode

A distraction-free mode that hides almost all application chrome.

Optional enhancements:

- dim surrounding paragraphs/pages;
- keep only current paragraph/chapter at full contrast;
- auto-hide pointer and controls;
- configurable reading ruler;
- fullscreen timer/progress indicator.

### 5.4 Comic Mode

- page-by-page navigation;
- right-to-left support;
- smart fit;
- optional panel zoom later;
- minimal controls.

## 6. Annotation system

Annotation is a first-class domain, not a viewer overlay.

### Annotation types

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
- Text box
- Link between annotations

### Highlight workflow

Text selection should open a compact floating action capsule with:

- last-used color;
- alternate colors;
- highlight;
- underline;
- add note;
- copy;
- tag;
- more actions.

A power-user **Auto Highlight** option turns every valid text selection into a highlight using the current style.

### Semantic highlight palettes

Users may use arbitrary colors, but Kola should ship optional semantic presets:

- Yellow — Important
- Blue — Definition
- Green — Evidence / Example
- Pink — Question
- Purple — Idea / Connection
- Orange — Review

The label, not the physical color, is the semantic value. Themes may remap colors for accessibility.

### Annotation panel

A right-side panel shows a chronological/document-order stream containing:

- selected quotation or screenshot;
- user note;
- page/chapter;
- tags;
- color/type;
- jump-to-source action.

Filters:

- type;
- tag;
- color;
- chapter;
- favorites;
- with notes only.

## 7. Knowledge features without cloud dependence

### 7.1 Collections

Documents can belong to multiple collections without being duplicated on disk.

### 7.2 Tags

Tags apply to documents and annotations.

### 7.3 Backlinks between annotations

Users can link two highlights/notes even when they belong to different documents.

### 7.4 Study Sheet

Generate a local, deterministic study sheet from selected annotations:

- grouped by chapter;
- grouped by tag;
- grouped by highlight category;
- optionally include surrounding context;
- export to Markdown/HTML/PDF later.

No generative AI is required.

### 7.5 Global local search

Search should cover:

- title;
- author;
- document body text;
- annotations;
- notes;
- tags.

Results jump directly to the source location.

## 8. Library experience

Library views:

- Home / Continue Reading
- All Documents
- Recent
- Favorites
- Collections
- Tags
- Annotated
- Unread / In Progress / Finished

Display options:

- responsive cover grid;
- dense list;
- compact table on desktop.

Import methods:

- Open File
- Open Folder
- drag and drop
- OS share/open-with integration
- mobile share sheet

Kola should support **linked files** (read in place) and **managed copies** (copied into Kola's library), with a clear user choice.

## 9. Reading quality features

- remember position per document;
- reading progress by percentage/page/chapter;
- estimated time remaining;
- bookmarks;
- history/back-forward navigation;
- smart table of contents;
- thumbnails;
- page labels;
- in-document search;
- case-sensitive and whole-word search;
- keyboard-only navigation;
- touch gestures;
- stylus-aware ink mode;
- optional keep-screen-awake;
- brightness overlay on mobile;
- custom page/text background;
- margin crop for PDFs;
- persistent crop presets;
- rotation;
- presentation/fullscreen mode;
- text-to-speech via platform-local voices in a later release.

## 10. Signature interaction: Peek

Kola should provide a lightweight **Peek** interaction for references and navigation targets.

Examples:

- hover/tap an internal PDF link to preview its destination;
- preview a footnote without leaving the current location;
- preview a figure/table/reference;
- press-and-hold a TOC item to preview the target page.

Opening the target pushes the current location onto navigation history, so Back returns exactly to the previous reading position.

## 11. Signature interaction: Reading Lens

A movable horizontal or rectangular lens that:

- isolates 1–5 lines;
- can dim or blur surrounding text;
- follows keyboard, mouse, touch or stylus;
- optionally advances line-by-line.

This is useful for dense academic reading and accessibility without altering the document.

## 12. Signature interaction: Annotation Rail

When the annotation panel is hidden, tiny nonintrusive markers on the document edge show where annotations exist. Hover/tap opens a compact preview. This gives spatial awareness without permanently consuming horizontal space.

## 13. Signature interaction: Command Palette

Desktop/tablet shortcut: `Ctrl/Cmd + K`.

Commands include:

- Open document
- Search library
- Go to page
- Go to chapter
- Toggle Flow Mode
- Toggle Focus Mode
- Add bookmark
- Change theme
- Change highlight tool
- Export annotations
- Open settings

Commands should be searchable and keyboard navigable.

## 14. Privacy and security

Core Kola must make **zero network requests while reading local documents**.

Requirements:

- no account;
- no cloud database;
- no remote analytics SDK;
- no advertising SDK;
- no remote fonts required;
- no document upload;
- no third-party AI calls;
- all indexes and thumbnails local;
- optional crash reports only if explicitly introduced and opt-in later;
- app lock/biometric lock can be added later using OS facilities;
- private collections may be encrypted later.

A future sync feature, if ever built, must be an optional separate capability and cannot become required for normal use.

## 15. Accessibility

Kola must be designed for accessibility from the first release:

- complete keyboard traversal;
- visible focus states;
- screen-reader semantics for interactive UI;
- sufficient contrast;
- reduced-motion option;
- large-text support;
- non-color annotation labels;
- configurable line spacing and width;
- dyslexia-friendly font option without making it the default;
- RTL document/UI awareness;
- keyboard shortcuts discoverable in UI.

## 16. Performance targets

Targets are budgets, not guarantees:

- app shell visible in < 1.5 s on a typical modern laptop after warm install;
- reader interaction at 60 fps where display permits;
- 120 Hz capable rendering where platform/device permits;
- page scrolling must never wait on database writes;
- thumbnails generated lazily;
- text indexing off the UI isolate;
- large PDF pages rendered on demand with bounded cache;
- library should remain responsive with 10,000 metadata records;
- opening a previously indexed document should avoid reparsing it unnecessarily.

## 17. Non-goals for v1

To keep the first product excellent rather than broad but weak:

- no accounts;
- no server backend;
- no collaboration;
- no cloud sync;
- no document editor comparable to Word;
- no generative AI assistant;
- no DRM bypass;
- no browser-first/web app requirement.

## 18. Definition of a successful v1

Kola v1 is successful when a user can install it on the major desktop/mobile platforms, import a PDF or EPUB, read it comfortably for hours, highlight and annotate it naturally, close the app, reopen it with perfect state restoration, search their local library, and export their work without creating an account or sending the document anywhere.

The product should feel intentionally designed for reading rather than like a file viewer with annotation buttons attached.