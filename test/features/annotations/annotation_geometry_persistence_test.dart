import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/core/database/kola_database.dart' hide Annotation;
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/features/annotations/data/drift_annotation_repository.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/library/data/drift_document_repository.dart';

void main() {
  test('PDF highlight quote, context, ranges, and geometry survive SQLite', () async {
    final KolaDatabase database = KolaDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final DriftDocumentRepository documents = DriftDocumentRepository(database);
    final DriftAnnotationRepository annotations = DriftAnnotationRepository(database);
    final DateTime now = DateTime.utc(2026, 9, 12, 15);

    await documents.upsert(
      KolaDocument(
        id: 'doc-highlight',
        source: DocumentSource(
          kind: DocumentSourceKind.linkedFile,
          uri: Uri.file('/tmp/highlight.pdf'),
        ),
        format: DocumentFormat.pdf,
        metadata: const DocumentMetadata(title: 'Highlight PDF'),
        importedAt: now,
        updatedAt: now,
      ),
    );

    await annotations.upsert(
      Annotation(
        id: 'highlight-1',
        documentId: 'doc-highlight',
        type: AnnotationType.highlight,
        anchor: AnnotationAnchor(
          documentId: 'doc-highlight',
          sourceLocator: DocumentLocation(
            scheme: 'pdf',
            data: const <String, Object?>{'page': 7, 'start': 100, 'end': 118},
            label: 'Page 7',
          ),
          exactQuote: 'persistent source',
          prefixContext: 'before ',
          suffixContext: ' after',
          logicalStart: 100,
          logicalEnd: 118,
          sourceGeometry: const <Map<String, Object?>>[
            <String, Object?>{
              'scheme': 'pdf',
              'coordinateSpace': 'pdfPagePoints',
              'page': 7,
              'start': 100,
              'end': 118,
              'left': 24.5,
              'top': 700.0,
              'right': 142.0,
              'bottom': 686.0,
            },
          ],
          formatSpecificFallback: const <String, Object?>{
            'ranges': <Map<String, Object?>>[
              <String, Object?>{
                'scheme': 'pdf',
                'page': 7,
                'start': 100,
                'end': 118,
              },
            ],
          },
        ),
        quote: 'persistent source',
        colorToken: 'highlight.yellow',
        semanticLabel: 'important',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final Annotation? stored = await annotations.getById('highlight-1');
    expect(stored, isNotNull);
    expect(stored!.anchor.exactQuote, 'persistent source');
    expect(stored.anchor.prefixContext, 'before ');
    expect(stored.anchor.suffixContext, ' after');
    expect(stored.anchor.logicalStart, 100);
    expect(stored.anchor.logicalEnd, 118);
    expect(stored.anchor.sourceGeometry.single['page'], 7);
    expect(stored.anchor.sourceGeometry.single['left'], 24.5);
    expect(stored.anchor.sourceGeometry.single['coordinateSpace'], 'pdfPagePoints');
    expect(stored.anchor.formatSpecificFallback['ranges'], isA<List<Object?>>());
  });
}
