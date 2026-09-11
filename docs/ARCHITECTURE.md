# Kola — Technical Architecture

## 1. Architecture decision

Kola should begin as a **Flutter/Dart local-first application** with a modular architecture and no server dependency.

### Why Flutter

Flutter currently supports Android, iOS, Windows, macOS and Linux from one application codebase. That directly matches Kola's deployment requirement while allowing custom rendering, animation, keyboard interactions, touch gestures and adaptive layouts.

### Why not Rust in v1

Rust is intentionally not part of the critical path for the first release. A Rust module can be introduced later for CPU-heavy OCR, document analysis, codecs or search workloads if profiling shows a measurable benefit.

The rule is simple: **do not add an FFI boundary before there is a performance or capability reason for one.**

## 2. Proposed technology stack

### Application framework

- Flutter
- Dart
- Material 3 primitives used selectively, with a custom Kola design system layered on top

### State management

Recommended: Riverpod

Use providers/controllers at feature boundaries. Avoid storing domain state directly inside widgets.

### Navigation

Recommended: go_router

Routes are lightweight because the reader itself should use internal tab/document navigation rather than creating a URL-style route for every page.

### Local database

- SQLite
- Drift as the typed Dart persistence layer
- SQLite FTS5 for local full-text search where available through the bundled SQLite engine

### PDF engine

Recommended initial engine: `pdfrx`, backed by PDFium.

Use the viewer/rendering layer behind a Kola adapter. Never expose package-specific types to the rest of the application.

### EPUB

Use an EPUB parser such as `epubx` behind the same document adapter interface. Kola owns rendering, theme, navigation and annotation behavior.

### Other formats

- TXT: native text parser
- Markdown: markdown parser -> normalized document tree
- HTML: sanitize and parse local HTML -> normalized document tree
- CBZ: ZIP reader -> ordered image sequence
- CBR: add later through a compatible archive implementation
- DOCX/DjVu: add later through separate adapters

### Filesystem

Use platform-safe Flutter filesystem APIs and abstractions. File imports must support both:

- linked mode: retain external file path/URI where the OS permits;
- managed mode: copy content into Kola's application library.

## 3. Repository structure

```text
kola/
├─ lib/
│  ├─ app/
│  │  ├─ kola_app.dart
│  │  ├─ router.dart
│  │  └─ bootstrap.dart
│  ├─ core/
│  │  ├─ database/
│  │  ├─ filesystem/
│  │  ├─ logging/
│  │  ├─ platform/
│  │  ├─ search/
│  │  └─ utils/
│  ├─ design_system/
│  │  ├─ color/
│  │  ├─ motion/
│  │  ├─ typography/
│  │  ├─ components/
│  │  └─ tokens/
│  ├─ document/
│  │  ├─ model/
│  │  ├─ adapters/
│  │  │  ├─ pdf/
│  │  │  ├─ epub/
│  │  │  ├─ markdown/
│  │  │  ├─ text/
│  │  │  ├─ html/
│  │  │  └─ comic/
│  │  ├─ parsing/
│  │  ├─ reflow/
│  │  └─ anchors/
│  ├─ features/
│  │  ├─ library/
│  │  ├─ reader/
│  │  ├─ annotations/
│  │  ├─ collections/
│  │  ├─ search/
│  │  ├─ settings/
│  │  ├─ import_export/
│  │  └─ command_palette/
│  └─ shared/
│     ├─ models/
│     └─ widgets/
├─ test/
├─ integration_test/
├─ docs/
├─ assets/
└─ tool/
```

Do not split this into many Dart packages prematurely. Start as a well-modularized app. Extract packages only when boundaries become stable or reusable.

## 4. Architectural layers

### Presentation layer

Flutter widgets, interaction controllers and view state.

Responsibilities:

- rendering;
- gestures;
- keyboard shortcuts;
- focus;
- visual selection;
- panels;
- animations.

It must not perform direct SQL or parse file formats.

### Application layer

Coordinates use cases such as:

- importDocument;
- openDocument;
- addAnnotation;
- changeReadingPosition;
- buildSearchIndex;
- exportAnnotations.

### Domain layer

Stable app-owned models and business rules.

Examples:

- Document
- DocumentLocation
- Annotation
- AnnotationAnchor
- Collection
- ReadingProgress
- SearchResult
- ReflowBlock

### Infrastructure layer

Package/platform implementations:

- PDFium/pdfrx;
- SQLite/Drift;
- filesystem;
- archive decoding;
- OS integrations.

Infrastructure always implements an app-owned interface.

## 5. The most important abstraction: DocumentAdapter

Every format implements the same conceptual contract.

```dart
abstract interface class DocumentAdapter {
  DocumentFormat get format;

  Future<DocumentMetadata> readMetadata(DocumentSource source);

  Future<DocumentHandle> open(DocumentSource source);

  Stream<IndexChunk> extractIndexableContent(DocumentHandle handle);

  Future<DocumentLocation?> resolveAnchor(
    DocumentHandle handle,
    AnnotationAnchor anchor,
  );

  Future<ExportResult> export(ExportRequest request);
}
```

A viewer must not ask, “Is this a PDF?” unless behavior is genuinely format-specific.

## 6. Normalized document model

Kola needs an internal structure for reflow, search and cross-format features.

```text
NormalizedDocument
 ├─ metadata
 ├─ sections[]
 │   ├─ heading
 │   └─ blocks[]
 │       ├─ ParagraphBlock
 │       ├─ HeadingBlock
 │       ├─ ListBlock
 │       ├─ QuoteBlock
 │       ├─ ImageBlock
 │       ├─ TableBlock
 │       └─ CodeBlock
 └─ sourceMap
```

Every text-bearing block contains source mapping information.

For PDF this includes page number and one or more source rectangles/quads.

For EPUB this includes spine item plus a stable DOM/CFI-like location and textual context.

For Markdown/TXT it includes source offsets.

## 7. Annotation anchoring

This is the hardest correctness problem in Kola and must be designed before UI polish.

### Never store only screen coordinates

Screen positions break when:

- zoom changes;
- device changes;
- window resizes;
- Flow Mode is enabled;
- font size changes.

### Hybrid anchor

Each text annotation should store multiple selectors:

```text
AnnotationAnchor
 ├─ documentId
 ├─ sourceLocator
 ├─ exactQuote
 ├─ prefixContext
 ├─ suffixContext
 ├─ logicalTextOffsets (when reliable)
 └─ sourceGeometry[] (when available)
```

For PDFs:

```text
PdfSourceLocator
 ├─ pageIndex
 ├─ quads[]
 └─ extractedTextRange
```

For EPUB:

```text
EpubSourceLocator
 ├─ spineIndex
 ├─ resourcePath
 ├─ elementPath / CFI-like locator
 └─ textOffset
```

Resolution strategy:

1. try exact structural/source locator;
2. verify quote text;
3. fall back to text offsets;
4. fall back to quote + prefix/suffix matching;
5. mark anchor as unresolved rather than silently attaching to the wrong text.

## 8. Flow Mode pipeline

### PDF

```text
PDF
 -> page text extraction
 -> glyph/word geometry
 -> line grouping
 -> block grouping
 -> column/reading-order analysis
 -> repeated header/footer detection
 -> semantic block classification
 -> source-mapped NormalizedDocument
 -> Flow renderer
```

### EPUB/HTML/Markdown

These formats are already structurally reflowable, so they skip most geometric reconstruction.

### Critical invariant

Every reflowed range must preserve enough source mapping to return to the original location.

## 9. Reader rendering architecture

The reader contains a stable shell and swappable content surfaces.

```text
ReaderShell
 ├─ ReaderTopBar
 ├─ LeftPanel (TOC / thumbnails / outline)
 ├─ ReaderSurface
 │   ├─ PdfPageSurface
 │   ├─ ReflowSurface
 │   ├─ EpubSurface
 │   └─ ComicSurface
 ├─ AnnotationRail
 ├─ SelectionToolbar
 └─ RightPanel (annotations / search / notes)
```

Panels should be overlays on compact devices and dockable on wide layouts.

## 10. Database model

Suggested tables:

### documents

- id
- content_hash
- source_kind
- source_uri/path
- managed_path
- format
- title
- subtitle
- authors
- language
- page_count
- cover_path/cache_key
- file_size
- modified_at
- imported_at
- last_opened_at
- status

### reading_states

- document_id
- locator_json
- progress
- zoom
- view_mode
- updated_at

### annotations

- id
- document_id
- type
- anchor_json
- quote
- note
- semantic_label
- color_token
- created_at
- updated_at
- deleted_at nullable

### tags

- id
- name

### annotation_tags

- annotation_id
- tag_id

### document_tags

- document_id
- tag_id

### collections

- id
- name
- parent_id nullable
- sort_order

### collection_documents

- collection_id
- document_id

### bookmarks

- id
- document_id
- anchor_json
- title
- created_at

### links

- id
- from_annotation_id
- to_annotation_id
- relation_type

### index metadata

Track parser/index versions so indexes can be rebuilt after parser improvements without corrupting user data.

## 11. Full-text search

Use a separate FTS index populated asynchronously.

Index logical chunks rather than whole documents:

- document id;
- section/chapter;
- source locator;
- normalized text.

Search result ranking should favor:

1. title exact match;
2. annotation/note exact match;
3. body phrase match;
4. body token match.

All search results must carry a resolvable source locator.

## 12. File identity

Paths alone are not stable enough.

Kola should compute a content fingerprint on import. For very large files, use a staged fingerprint strategy and compute the strong hash asynchronously.

The system must be able to recognize a moved/renamed file without duplicating all annotations.

## 13. Import pipeline

```text
User selects file
 -> validate readable format
 -> identify/fingerprint
 -> detect existing document
 -> choose linked/managed policy
 -> create metadata record
 -> read metadata/cover
 -> open immediately
 -> background text extraction/indexing
 -> background thumbnail generation
```

Opening must not wait for full indexing.

## 14. Background work

Use Dart isolates/background workers for:

- text extraction;
- full-text indexing;
- thumbnail generation;
- content fingerprinting;
- PDF reflow analysis;
- export jobs.

UI state must never block on those jobs unless the requested feature truly requires their result.

## 15. Caching

Caches are disposable and versioned.

Potential caches:

- page raster cache;
- page thumbnail cache;
- cover cache;
- extracted text cache;
- reflow analysis cache;
- search index.

User-generated data is not a cache and must never be deleted by “Clear cache.”

## 16. Export architecture

Export targets should be separate services:

- Markdown annotations
- JSON Kola backup
- HTML notes
- PDF with embedded annotations where technically supported
- annotation sidecar bundle

Export must never mutate the source file unless the user explicitly chooses an in-place operation in a future feature.

## 17. Undo/redo

Annotation edits need command-based undo/redo.

Examples:

- add annotation;
- delete annotation;
- change color;
- move ink stroke;
- edit note;
- change crop region.

Database persistence can be debounced behind the in-memory command state.

## 18. Platform adaptation

One codebase does not mean identical UI.

### Desktop

- resizable/dockable sidebars;
- tabbed documents;
- hover states;
- right click;
- keyboard shortcuts;
- drag and drop;
- command palette.

### Tablet

- split panels;
- stylus-first annotation;
- touch targets;
- detachable/overlay tool palettes.

### Phone

- one primary surface;
- bottom sheets instead of permanent sidebars;
- edge-to-edge reading;
- Flow Mode emphasized;
- thumb-reachable controls.

## 19. Design system architecture

Never scatter raw colors, radii or durations through widgets.

Use tokens:

```text
KolaColor
KolaSpacing
KolaRadius
KolaTypography
KolaElevation
KolaMotion
KolaIconSize
KolaBreakpoint
```

Reading themes are separate from application chrome themes.

This distinction allows a dark app shell with a sepia book page, for example.

## 20. Testing strategy

### Unit tests

- annotation anchor resolution;
- document fingerprinting;
- import deduplication;
- reading progress conversion;
- reflow block ordering;
- database migrations;
- export formatting.

### Golden tests

- reader toolbars;
- panels;
- compact/wide layouts;
- themes;
- selection UI.

### Integration tests

For each supported platform where CI is practical:

1. import a sample document;
2. open it;
3. navigate;
4. create annotation;
5. restart app;
6. verify persistence;
7. export annotation.

### Corpus tests

Maintain a legal test corpus containing:

- simple PDF;
- multi-column PDF;
- scanned PDF;
- rotated PDF;
- mixed text/images;
- RTL content;
- EPUB 2;
- EPUB 3;
- malformed-but-common documents.

## 21. Error philosophy

Document readers encounter broken files. Kola should degrade gracefully.

Examples:

- Flow Mode failure -> remain in Page Mode, explain why;
- failed metadata extraction -> open with filename as title;
- failed index -> reading still works;
- missing linked file -> offer Locate File;
- partially unresolved annotations -> preserve them and show repair state.

Never turn a secondary feature failure into an inability to read the file.

## 22. Future Rust boundary

If a native core becomes justified, isolate it behind services such as:

```text
DocumentAnalysisEngine
OcrEngine
ArchiveEngine
SearchEngine
```

Use a bridge such as flutter_rust_bridge only after a measured need appears. Domain models should remain independent from FFI representations.

## 23. Architecture rule summary

1. Flutter owns the application and UI.
2. SQLite/Drift owns durable local metadata and annotations.
3. Source files remain separate from Kola's metadata.
4. Every format is hidden behind a DocumentAdapter.
5. Annotation anchors are source-based, not screen-based.
6. Flow Mode and Page Mode share the same document identity and annotation model.
7. Parsing/indexing happens away from the UI isolate.
8. Caches are disposable; user data is not.
9. Platform adaptation is allowed; product behavior stays consistent.
10. Add native complexity only when profiling proves it is needed.
