# Kola — Product and Technology Research Notes

Research snapshot: September 2026.

This file records the reasoning behind Kola's initial product and architecture direction. It is not a dependency lockfile; package choices should still be validated during implementation.

## 1. Cross-platform application framework

Flutter is the recommended application framework because its current supported deployment targets include Android, iOS, Windows, macOS and Linux and it is specifically designed for natively compiled multi-platform applications from one codebase.

References:

- https://docs.flutter.dev/reference/supported-platforms
- https://docs.flutter.dev/platform-integration

## 2. PDF rendering

`pdfrx` is a strong initial candidate for Kola's PDF adapter. As of this research snapshot it provides a Flutter PDF viewer/manipulation layer backed by PDFium and advertises support for Android, iOS, Windows, macOS and Linux (plus web, though Kola is not web-first).

The Kola architecture deliberately hides it behind an app-owned adapter so the engine can be replaced or supplemented later.

Reference:

- https://pub.dev/packages/pdfrx

## 3. Local persistence

Drift is the recommended typed persistence layer on top of SQLite. It supports the native platforms Kola targets, provides migrations and transactions, and is appropriate for a local-first relational model containing documents, annotations, tags, collections and reading state.

Reference:

- https://pub.dev/packages/drift

## 4. EPUB

`epubx` is an initial candidate for EPUB parsing. Kola should not couple UI state directly to its types; EPUB content should be converted into Kola's normalized document structures.

Reference:

- https://pub.dev/packages/epubx

## 5. Reflow / Reading Mode research

### Adobe Acrobat Liquid Mode

Adobe's Liquid Mode demonstrates the value of dynamically reflowing PDF content for small screens and exposing text-size/spacing controls. Adobe also documents important compatibility constraints for complex, scanned, encrypted, large, or otherwise unsupported files.

Product lesson for Kola:

- reflow should be confidence-based rather than promised for every PDF;
- Page Mode must remain a reliable fallback;
- typography customization materially improves phone reading.

References:

- https://helpx.adobe.com/acrobat/mobile/view-manage-files/liquid-mode.html
- https://helpx.adobe.com/acrobat/mobile/get-started/technical-requirements.html

### Zotero 10 Reading Mode

Zotero 10's 2026 Reading Mode is particularly relevant. It provides a reflowable PDF view while maintaining annotation interoperability with the original PDF view and keeps images/tables represented when they cannot safely become text.

Product lesson for Kola:

- Page Mode and Flow Mode should be views over one source-mapped document;
- highlights made in reflow should resolve back to the source;
- unsupported visual structures should remain source-preserving blocks rather than being silently discarded.

Reference:

- https://www.zotero.org/blog/zotero-10/

## 6. Annotation architecture research

Zotero stores its own PDF annotations in its database rather than continuously mutating the PDF itself. Zotero cites benefits such as fast updates and enabling richer application behavior, while still allowing users to export a PDF with embedded annotations.

Product lesson for Kola:

- Kola annotations should live in the app database by default;
- source documents should not be repeatedly rewritten;
- export should provide interoperability and portability.

References:

- https://www.zotero.org/support/kb/annotations_in_database
- https://www.zotero.org/support/pdf_reader

## 7. Knowledge-work interaction research

LiquidText demonstrates the usefulness of a parallel annotation workspace and explicit connections among excerpts from distant document locations.

Product lesson for Kola:

- annotation notes should be visible alongside documents on wide screens;
- linked annotations/backlinks can be useful without requiring a cloud graph or AI system.

Reference:

- https://www.liquidtext.net/features

## 8. Keyboard-first reading research

Readwise Reader documents keyboard-oriented reading and annotation workflows, including paragraph navigation, highlighting, tagging and notes.

Product lesson for Kola:

- desktop reading should not require the mouse;
- highlight/note/tag actions deserve fast keyboard paths;
- shortcut discoverability is important.

References:

- https://docs.readwise.io/reader/docs/faqs/highlights-tags-notes
- https://docs.readwise.io/reader/docs

## 9. Product gap Kola should target

Many strong readers optimize for one of these groups:

- PDF review;
- academic reference management;
- read-it-later/cloud workflows;
- ebook reading;
- visual research workspaces.

Kola's proposed gap is the combination of:

1. fully local operation;
2. no mandatory account/subscription;
3. desktop + mobile from one product;
4. PDF and EPUB as equal first-class formats;
5. source-linked reflow;
6. one annotation model across formats;
7. polished keyboard, touch and stylus interaction;
8. user-owned exports and backups.

The goal should not be to duplicate every feature from every competitor. Kola should win on reading quality, annotation correctness, privacy, consistency and portability.

## 10. Architectural caution

A document reader is deceptively difficult. The largest engineering risks are not visual:

- text selection correctness;
- mapping selections to stable source anchors;
- PDF reading order;
- complex/scanned PDFs;
- input differences among mouse, touch and stylus;
- corrupted documents;
- annotation persistence and export;
- memory usage on huge files.

The roadmap therefore prioritizes reader and annotation correctness before broad format support or highly decorative UI.