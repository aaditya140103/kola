# Kola — Technical Architecture

## 1. Architecture decision

Kola remains a **Flutter/Dart local-first application** with no server dependency, but the document subsystem is now designed as a universal content engine rather than a PDF/EPUB-centric reader.

The architecture must support:

- Linux
- Windows
- macOS
- Android
- iOS

from one application repository while allowing format-specific local engines behind stable interfaces.

## 2. Core architectural idea

Every document format is normalized into a shared semantic representation called the **Kola Document Graph (KDG)**.

```text
Source file
   -> FormatRegistry
   -> DocumentAdapter
      -> fidelity/source representation
      -> semantic extraction
      -> source mapping
   -> KolaDocumentGraph
      -> Flow Mode
      -> Search
      -> Progress
      -> Annotation resolution
      -> Export
```

This makes Flow Mode universal rather than format-specific.

## 3. Proposed technology stack

### Application framework

- Flutter
- Dart
- custom Kola design system over selected Material primitives

### State and navigation

- Riverpod
- go_router

### Durable local storage

- SQLite
- Drift
- SQLite FTS5 where supported by the bundled SQLite build

### Primary format engines

Initial candidates:

- PDF: PDFium through `pdfrx`
- EPUB/HTML-family: local structured parser and renderer
- Office Open XML: local ZIP/XML parsing through adapter-specific code/libraries
- spreadsheets: local workbook parser behind a Kola adapter
- archives/comics: local archive decoder
- legacy ebook formats: dedicated local parser or conversion adapter

No package-specific types may escape into the domain layer.

### Rust/native core policy

Rust is no longer ruled out as strongly as in the first architecture draft because broad format support can justify a portable parsing core.

However, Rust should still be introduced **per capability**, not as a rewrite of the application.

Likely future native boundaries:

```text
UniversalDocumentCore
ArchiveEngine
LegacyEbookEngine
OcrEngine
OfficeBinaryEngine
SearchAccelerator
```

Flutter remains the application/UI owner.

## 4. Repository structure

```text
kola/
├─ lib/
│  ├─ app/
│  ├─ core/
│  │  ├─ database/
│  │  ├─ filesystem/
│  │  ├─ search/
│  │  ├─ jobs/
│  │  └─ platform/
│  ├─ design_system/
│  │  ├─ tokens/
│  │  ├─ themes/
│  │  ├─ backgrounds/
│  │  ├─ typography/
│  │  └─ components/
│  ├─ document/
│  │  ├─ registry/
│  │  ├─ model/
│  │  ├─ graph/
│  │  ├─ adapters/
│  │  │  ├─ pdf/
│  │  │  ├─ epub/
│  │  │  ├─ office_text/
│  │  │  ├─ presentation/
│  │  │  ├─ spreadsheet/
│  │  │  ├─ comic/
│  │  │  ├─ legacy_ebook/
│  │  │  ├─ fixed_layout/
│  │  │  └─ plain_text/
│  │  ├─ flow/
│  │  ├─ anchors/
│  │  ├─ progress/
│  │  └─ conversion/
│  ├─ features/
│  │  ├─ library/
│  │  ├─ reader/
│  │  ├─ annotations/
│  │  ├─ collections/
│  │  ├─ search/
│  │  ├─ progress/
│  │  ├─ themes/
│  │  ├─ settings/
│  │  ├─ import_export/
│  │  └─ command_palette/
│  └─ shared/
├─ native/              # optional portable native/Rust capabilities later
├─ test/
├─ integration_test/
├─ docs/
├─ assets/
└─ tool/
```

## 5. FormatRegistry

The `FormatRegistry` detects the actual format using extension, MIME hints, magic bytes/container inspection, and adapter probes.

Never trust the extension alone.

Conceptual API:

```dart
abstract interface class FormatRegistry {
  Future<FormatMatch> detect(DocumentSource source);
  DocumentAdapter adapterFor(FormatMatch match);
}
```

## 6. DocumentAdapter

Every format implements the same contract.

```dart
abstract interface class DocumentAdapter {
  DocumentFormat get format;
  FormatCapabilities get capabilities;

  Future<DocumentMetadata> readMetadata(DocumentSource source);
  Future<DocumentHandle> open(DocumentSource source);

  Future<FidelityDescriptor?> buildFidelityView(DocumentHandle handle);

  Stream<GraphChunk> buildDocumentGraph(
    DocumentHandle handle,
    GraphBuildOptions options,
  );

  Stream<IndexChunk> extractIndexableContent(DocumentHandle handle);

  Future<DocumentLocation?> resolveAnchor(
    DocumentHandle handle,
    AnnotationAnchor anchor,
  );

  Future<ExportResult> export(ExportRequest request);
}
```

## 7. Capability-driven UI

Each adapter advertises capabilities:

```text
FormatCapabilities
 - fidelityView
 - flowMode
 - textSelection
 - textSearch
 - textAnnotations
 - areaAnnotations
 - inkAnnotations
 - spreadsheetRanges
 - slideRegions
 - outline
 - embeddedMedia
 - localOcr
 - exportEmbeddedAnnotations
```

The UI responds to capabilities instead of branching on `if (pdf)` or `if (epub)`.

## 8. Kola Document Graph (KDG)

The KDG is the normalized semantic structure used by Flow Mode, search, coverage tracking, and cross-format annotations.

```text
KolaDocumentGraph
 ├─ metadata
 ├─ root
 │  └─ semantic nodes
 │      ├─ Section
 │      ├─ Heading
 │      ├─ Paragraph
 │      ├─ List
 │      ├─ Quote
 │      ├─ Image
 │      ├─ Figure
 │      ├─ Caption
 │      ├─ Table
 │      ├─ TableRow
 │      ├─ TableCell
 │      ├─ Code
 │      ├─ Footnote
 │      ├─ Slide
 │      ├─ SpeakerNotes
 │      ├─ Sheet
 │      ├─ CellRange
 │      ├─ FormulaDisplay
 │      └─ SourceVisualBlock
 └─ sourceMap
```

Every graph node receives a stable Kola node id and, where possible, one or more source locators.

## 9. Source mapping by format

### PDF

- page index
- text range
- glyph/word quads

### EPUB/HTML

- spine/resource path
- element path / CFI-like locator
- text offsets

### DOCX/ODT

- part/resource id
- paragraph/run identity
- table/row/cell coordinates
- text offsets

### PPTX/ODP

- slide index
- object identity
- text run
- geometry rectangle
- notes location

### XLSX/ODS

- sheet identity
- cell/range coordinate
- table/named-range identity

### comics/images

- page/image index
- normalized image rectangle
- OCR text region where available

## 10. Universal Flow Mode pipeline

```text
Adapter
 -> structural extraction
 -> geometry extraction where relevant
 -> semantic classification
 -> reading-order inference
 -> source-map generation
 -> KDG chunks
 -> Flow renderer
```

### Flow quality classes

- **Native**: structure already semantic.
- **Reconstructed**: semantic order inferred from positioned objects.
- **Extracted**: content is transformed into a readable linear representation.
- **OCR**: text comes from local OCR of visual content.

The quality class is stored with the graph and can be surfaced in UI.

### Source-preserving fallback

When flattening a visual object would lose meaning, insert a `SourceVisualBlock` rather than discarding it.

Examples:

- complex equation;
- chart;
- dense spreadsheet region;
- slide diagram;
- unusual PDF table.

The block keeps a **View in original** action.

## 11. Fidelity surfaces

Reader surfaces are format-specific but share one shell:

```text
ReaderShell
 ├─ FidelitySurface
 │   ├─ PdfPageSurface
 │   ├─ WordLayoutSurface
 │   ├─ SlideSurface
 │   ├─ SheetSurface
 │   ├─ ComicSurface
 │   └─ GenericFixedLayoutSurface
 ├─ FlowSurface
 ├─ AnnotationRail
 ├─ SelectionToolbar
 ├─ ProgressOverlay
 └─ Panels
```

A format may initially have Flow Mode before its fidelity renderer reaches full accuracy. The architecture permits this without fragmenting annotations.

## 12. Annotation anchoring

Never store only screen coordinates.

```text
AnnotationAnchor
 ├─ documentId
 ├─ sourceLocator
 ├─ graphNodeIds[]
 ├─ exactQuote
 ├─ prefixContext
 ├─ suffixContext
 ├─ logicalOffsets
 ├─ sourceGeometry[]
 └─ formatSpecificFallback
```

Resolution order:

1. exact structural/source locator;
2. graph-node mapping;
3. quote verification;
4. logical offsets;
5. quote + surrounding-context match;
6. unresolved state rather than incorrect attachment.

## 13. Reading progress model

Kola tracks two separate concepts.

### PositionProgress

Where the current locator sits in the canonical KDG traversal.

```text
position = weightedOffset(currentLocator) / totalWeightedContent
```

Format-specific labels can still be shown beside the percentage.

### CoverageProgress

Which semantic blocks/ranges have actually been meaningfully viewed.

A block can become covered when:

- a minimum percentage of it enters the viewport;
- it remains visible past a configurable dwell threshold;
- the user explicitly marks it read.

Coverage is stored efficiently as ranges/bitsets keyed to graph version.

### Why both matter

Jumping to the last page can set position near 100% but should not set reading coverage near 100%.

### Spreadsheet coverage

For spreadsheets, the canonical Flow traversal is used for completion. Fidelity sheet/grid navigation records viewed ranges, which map back to graph regions.

### Presentation coverage

Slides become canonical units; speaker notes and extracted slide content contribute to per-slide weight.

## 14. Database additions

### documents

- id
- content_hash
- source_kind
- source_uri/path
- managed_path
- format
- title
- authors
- language
- cover_path/cache_key
- file_size
- imported_at
- last_opened_at
- support_status
- parser_version

### reading_states

- document_id
- locator_json
- position_progress
- view_mode
- zoom
- active_theme_id
- updated_at

### reading_coverage

- document_id
- graph_version
- coverage_blob / range representation
- covered_weight
- total_weight
- completion_state
- reading_time_ms
- updated_at

### reading_sessions

- id
- document_id
- started_at
- ended_at
- active_ms
- start_locator
- end_locator

### themes

- id
- kind (`app`, `reader`, `ambient`)
- name
- definition_json
- built_in
- updated_at

Existing annotation, tag, collection, bookmark, link, and index tables remain.

## 15. Theme architecture

Application chrome and reading surfaces are independent.

```text
ThemeController
 ├─ AppTheme
 ├─ ReaderTheme
 └─ AmbientBackground
```

### AppTheme

Controls navigation, panels, chrome, accents, borders, and system brightness behavior.

### ReaderTheme

Controls text, links, selection, highlight remapping, document/page background, and Flow Mode typography defaults.

### AmbientBackground

Controls the area behind or around the document:

- color
- gradient
- texture
- local image
- blur strength

All custom themes are local data and exportable in the Kola backup.

## 16. Search architecture

The search index consumes KDG chunks rather than raw format-specific structures.

This allows the same search pipeline to index:

- ebook text;
- PDF text;
- DOCX body;
- presentation text and notes;
- spreadsheet cells;
- OCR blocks;
- annotations and notes.

Every search result includes a source-resolvable locator.

## 17. Import pipeline

```text
User selects file
 -> detect actual format
 -> fingerprint source
 -> choose adapter
 -> create document record
 -> read metadata
 -> open fidelity or Flow surface immediately
 -> progressively build KDG
 -> progressively index text
 -> generate thumbnails/cover
 -> initialize progress map
```

Opening must not wait for complete graph construction.

## 18. Local conversion adapters

Some legacy formats may be converted locally into an intermediate representation.

Rules:

- original file is immutable;
- conversion output is cache data;
- no upload/service dependency;
- source identity is preserved;
- source-to-graph mapping is retained when technically possible;
- macros/scripts are never executed.

## 19. Background work

Use isolates or native workers for:

- parsing;
- graph construction;
- text extraction;
- OCR;
- thumbnails;
- indexing;
- hashing;
- legacy conversion;
- spreadsheet region analysis;
- presentation extraction;
- export.

## 20. Security model for rich files

- macros disabled;
- embedded scripts disabled by default;
- document-triggered network requests blocked by default;
- HTML/EPUB active content sandboxed;
- parsers treated as an untrusted-input boundary;
- malformed archives have decompression and size guards;
- file parsing failures must not corrupt Kola's database.

## 21. Testing corpus

The legal test corpus should grow to include:

- simple, multi-column, scanned, rotated, RTL and image-heavy PDFs;
- EPUB 2/3 and KEPUB;
- MOBI/AZW3/FB2 and legacy ebook samples;
- DOCX/ODT/RTF;
- PPTX/ODP;
- XLSX/XLS/ODS/CSV;
- CBZ/CBR/CB7;
- DjVu;
- malformed but common files;
- huge spreadsheets and slide decks;
- files with thousands of annotations.

## 22. Architecture rules

1. Flutter owns the product UI and application lifecycle.
2. SQLite/Drift owns durable local state.
3. Source files remain separate from Kola user data.
4. Every format is behind a `DocumentAdapter`.
5. Every readable format attempts to produce KDG content.
6. Flow Mode renders KDG, not format-specific UI.
7. Fidelity View and Flow Mode share document identity and annotation anchors.
8. Reading position and reading coverage are separate metrics.
9. Themes/backgrounds are data-driven and separate from document parsing.
10. Parsing/indexing/OCR never block the UI thread.
11. Caches are disposable; annotations/progress/themes are not.
12. Add native/Rust complexity only where capability or profiling justifies it.
13. Never execute macros or bypass DRM.
14. If semantic reconstruction is uncertain, preserve the original visual content and say so.