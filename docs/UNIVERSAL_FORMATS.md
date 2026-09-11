# Kola — Universal Format Support Strategy

Kola's long-term format goal is **market-complete local reading support**: if a file is a commonly used unencrypted ebook, document, presentation, spreadsheet, comic, text, or page-oriented publication, Kola should aim to open it, index it, track progress, annotate it, and expose a Flow Mode representation.

This is a product target, not a claim that every proprietary or DRM-protected file can be decoded. Kola must never bypass DRM or ship legally questionable decoders.

## 1. Universal rule

Every format plugs into the same pipeline:

```text
Source File
   -> FormatRegistry
   -> DocumentAdapter
      -> Fidelity representation
      -> Semantic extraction
      -> source map
   -> KolaDocumentGraph
      -> Flow Mode
      -> Search
      -> Progress
      -> Annotations
      -> Export
```

A format is considered first-class when it can provide:

1. metadata;
2. a readable source/fidelity view where practical;
3. semantic content for Flow Mode;
4. stable source locators;
5. local search text;
6. annotation anchors;
7. progress information.

## 2. Ebook families

Kola should target read support for the major unencrypted ebook families used in the market:

- EPUB 2 / EPUB 3
- KEPUB
- MOBI / Mobi6 / KF8
- AZW / AZW3 / compatible unencrypted Kindle containers
- AZW4 where technically possible without DRM
- FB2 / FBZ
- PRC
- PDB variants that can be safely identified
- PML / PMLZ
- LIT
- LRF
- RB
- SNB
- TCR
- CHM
- HTML / HTMLZ
- OEB / OPF-based open ebook packages
- TXT / TXTZ
- RTF
- PDF
- DjVu with text extraction and OCR fallback where possible
- DAISY / DTBook-compatible publications as an accessibility expansion

Exploratory/proprietary formats may include KFX, Apple Books-specific packages, WPS ebook formats, and other vendor containers when a legal, maintainable parser is available.

### DRM policy

Kola may open an unencrypted file in a supported container. It will not remove, defeat, or bypass DRM.

## 3. Comics and image publications

- CBZ
- CBR
- CB7
- CBC
- image folders
- ZIP/7z/RAR comic archives when the archive implementation is legally distributable
- common image formats used as pages: PNG, JPEG, WebP, GIF, AVIF, TIFF where decoder support exists

## 4. Word-processing documents

- DOCX
- DOC
- ODT
- RTF
- TXT
- Markdown
- HTML
- Pages, when a maintainable local parser is available
- WPS Writer formats where practical

Kola is a reader/annotator, not a full Word replacement. Editing source document layout is outside the core scope.

## 5. Presentations

- PPTX
- PPT
- ODP
- Keynote, when a maintainable local parser is available

Presentation Fidelity View shows slide structure. Flow Mode linearizes each slide into a semantic reading sequence such as title, subtitle, text groups, speaker notes, tables, images/captions, and accessible descriptions while preserving slide/source coordinates.

## 6. Spreadsheets and tabular documents

Primary targets:

- XLSX
- XLSM read-only, with macros never executed
- XLSB
- XLS
- ODS
- FODS
- CSV
- TSV
- Numbers where parser support exists

Additional legacy/tabular formats can be added through the adapter registry, including DBF, SYLK, DIF, Lotus/Works/Quattro families where a safe local parser is available.

Spreadsheet Fidelity View is a sheet/grid view. Flow Mode exposes a semantic traversal:

```text
Workbook
 -> Sheet
    -> named range / table / used region
       -> heading row
       -> row groups
       -> cell content
       -> comments/notes
```

Kola never executes spreadsheet macros, embedded scripts, or active content while reading.

## 7. Fixed-layout and publishing formats

- PDF
- XPS / OXPS
- DjVu
- PostScript/EPS as a later conversion adapter if a safe local renderer is available
- scanned image documents through OCR-capable adapters

## 8. Text and markup formats

- TXT
- Markdown
- HTML
- XHTML
- XML when a readable structure can be inferred
- reStructuredText
- AsciiDoc
- source-code/text files through a syntax-aware reading adapter as a later convenience feature

## 9. Flow Mode support levels

Flow Mode is available conceptually for **every readable document**, but the quality depends on what the source exposes.

### Level A — Native semantic flow

Examples: EPUB, HTML, Markdown, TXT, well-structured DOCX/ODT.

Structure is already explicit, so Kola preserves headings, lists, links, tables, images, footnotes, and reading order directly.

### Level B — Reconstructed semantic flow

Examples: digital PDF, PPTX, some DOCX/PPT/ODF documents.

Kola reconstructs reading order from positioned content while retaining source mapping.

### Level C — Extracted flow

Examples: spreadsheets, complex slide decks, legacy document containers.

Kola produces a readable semantic sequence from cells, text boxes, objects, notes, and metadata while Fidelity View preserves the original spatial layout.

### Level D — OCR flow

Examples: scanned PDF, scanned DjVu, image-only pages.

Kola locally OCRs visible content when an OCR engine is available. OCR-derived text is clearly marked and retains page/image coordinates.

### Critical invariant

Flow Mode must never silently pretend to be more accurate than it is. Each document can expose a confidence/capability state. If a block cannot be safely linearized, Flow Mode embeds a source-preserving visual block with a **View in original** action.

## 10. Format capability model

Each adapter advertises capabilities rather than forcing global assumptions:

```text
FormatCapabilities
 - fidelityView
 - flowMode
 - textSelection
 - search
 - textAnnotations
 - areaAnnotations
 - inkAnnotations
 - tableModel
 - outline
 - embeddedMedia
 - localOcr
 - exportEmbeddedAnnotations
```

The UI is driven by capabilities, not filename extensions.

## 11. Local conversion policy

Kola may locally convert a legacy format into an internal representation for reading, but:

- the original file remains untouched;
- conversions happen on-device;
- temporary conversions are cache data;
- annotations point back to stable source identity and source locators when possible;
- the user is never required to upload a document to a service.

## 12. Security rules for rich documents

- never execute Office macros;
- never execute embedded JavaScript by default;
- sandbox local HTML/EPUB scripted content;
- block external network loads from documents by default;
- treat embedded objects as untrusted input;
- parsers operate with bounded memory/time where practical;
- corrupted files must fail gracefully without damaging the library.

## 13. Support status vocabulary

Every format in settings/help should show one of:

- **First-class** — Fidelity View + Flow Mode + search + annotations + progress.
- **Readable** — reliable reading and Flow Mode, but some source features may not round-trip.
- **Preview** — experimental parser/renderer; annotations are preserved by Kola even if fidelity is incomplete.
- **Unsupported/DRM** — cannot legally or safely decode the file.

This avoids marketing claims that exceed actual parser quality while still keeping the product goal broad.