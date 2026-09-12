import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:kola/document/text/document_text_selection.dart';
import 'package:kola/features/annotations/application/annotation_creation_service.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/annotations/domain/annotation_repository.dart';

void main() {
  test('single-page selection becomes a source-linked highlight anchor', () async {
    final _MemoryAnnotationRepository repository = _MemoryAnnotationRepository();
    final DateTime now = DateTime.utc(2026, 9, 12, 13);
    final AnnotationCreationService service = AnnotationCreationService(
      repository,
      idGenerator: () => 'highlight-1',
      clock: () => now,
    );
    final KolaDocument document = KolaDocument(
      id: 'doc-1',
      source: DocumentSource(
        kind: DocumentSourceKind.linkedFile,
        uri: Uri.file('/tmp/paper.pdf'),
      ),
      format: DocumentFormat.pdf,
      metadata: const DocumentMetadata(title: 'Paper'),
      importedAt: now,
      updatedAt: now,
    );
    final DocumentTextSelection selection = DocumentTextSelection(
      documentId: document.id,
      text: 'source linked text',
      ranges: <DocumentTextSelectionRange>[
        DocumentTextSelectionRange(
          location: DocumentLocation(
            scheme: 'pdf',
            data: const <String, Object?>{'page': 4, 'start': 12, 'end': 30},
            label: 'Page 4',
          ),
          start: 12,
          end: 30,
          text: 'source linked text',
          prefixContext: 'before ',
          suffixContext: ' after',
          rects: const <DocumentRect>[
            DocumentRect(left: 10, top: 90, right: 80, bottom: 76),
            DocumentRect(left: 10, top: 72, right: 60, bottom: 58),
          ],
        ),
      ],
    );

    final Annotation annotation = await service.createHighlight(
      document: document,
      selection: selection,
    );

    expect(annotation.id, 'highlight-1');
    expect(annotation.type, AnnotationType.highlight);
    expect(annotation.quote, 'source linked text');
    expect(annotation.colorToken, 'highlight.yellow');
    expect(annotation.semanticLabel, 'important');
    expect(annotation.anchor.sourceLocator?.scheme, 'pdf');
    expect(annotation.anchor.sourceLocator?.data['page'], 4);
    expect(annotation.anchor.logicalStart, 12);
    expect(annotation.anchor.logicalEnd, 30);
    expect(annotation.anchor.exactQuote, 'source linked text');
    expect(annotation.anchor.prefixContext, 'before ');
    expect(annotation.anchor.suffixContext, ' after');
    expect(annotation.anchor.sourceGeometry, hasLength(2));
    expect(annotation.anchor.sourceGeometry.first['coordinateSpace'], 'pdfPagePoints');
    expect(annotation.anchor.sourceGeometry.first['page'], 4);
    expect(annotation.anchor.sourceGeometry.first['left'], 10.0);
    expect(repository.saved, same(annotation));
  });

  test('multi-page selection preserves per-page fallback ranges', () async {
    final _MemoryAnnotationRepository repository = _MemoryAnnotationRepository();
    final DateTime now = DateTime.utc(2026, 9, 12, 14);
    final AnnotationCreationService service = AnnotationCreationService(
      repository,
      idGenerator: () => 'highlight-2',
      clock: () => now,
    );
    final KolaDocument document = KolaDocument(
      id: 'doc-2',
      source: DocumentSource(
        kind: DocumentSourceKind.linkedFile,
        uri: Uri.file('/tmp/multi.pdf'),
      ),
      format: DocumentFormat.pdf,
      metadata: const DocumentMetadata(title: 'Multi'),
      importedAt: now,
      updatedAt: now,
    );

    final Annotation annotation = await service.createHighlight(
      document: document,
      selection: DocumentTextSelection(
        documentId: document.id,
        text: 'end of page\nstart of next',
        ranges: <DocumentTextSelectionRange>[
          DocumentTextSelectionRange(
            location: DocumentLocation(
              scheme: 'pdf',
              data: const <String, Object?>{'page': 2, 'start': 90, 'end': 101},
              label: 'Page 2',
            ),
            start: 90,
            end: 101,
            text: 'end of page',
            rects: const <DocumentRect>[
              DocumentRect(left: 20, top: 50, right: 90, bottom: 38),
            ],
          ),
          DocumentTextSelectionRange(
            location: DocumentLocation(
              scheme: 'pdf',
              data: const <String, Object?>{'page': 3, 'start': 0, 'end': 13},
              label: 'Page 3',
            ),
            start: 0,
            end: 13,
            text: 'start of next',
            rects: const <DocumentRect>[
              DocumentRect(left: 20, top: 740, right: 100, bottom: 728),
            ],
          ),
        ],
      ),
    );

    expect(annotation.anchor.sourceLocator?.data['page'], 2);
    expect(annotation.anchor.sourceLocator?.data['endPage'], 3);
    expect(annotation.anchor.logicalStart, isNull);
    expect(annotation.anchor.logicalEnd, isNull);
    final Object? ranges = annotation.anchor.formatSpecificFallback['ranges'];
    expect(ranges, isA<List<Object?>>());
    expect(ranges as List<Object?>, hasLength(2));
    expect(annotation.anchor.sourceGeometry.map((item) => item['page']), <Object?>[2, 3]);
  });
}

final class _MemoryAnnotationRepository implements AnnotationRepository {
  Annotation? saved;

  @override
  Future<Annotation?> getById(String id) async => saved?.id == id ? saved : null;

  @override
  Future<void> remove(String id) async {
    if (saved?.id == id) saved = null;
  }

  @override
  Future<void> upsert(Annotation annotation) async {
    saved = annotation;
  }

  @override
  Stream<List<Annotation>> watchForDocument(String documentId) {
    final Annotation? annotation = saved;
    if (annotation == null || annotation.documentId != documentId) {
      return Stream<List<Annotation>>.value(const <Annotation>[]);
    }
    return Stream<List<Annotation>>.value(<Annotation>[annotation]);
  }
}
