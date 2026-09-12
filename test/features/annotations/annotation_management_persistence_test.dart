import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/core/database/kola_database.dart' hide Annotation;
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/features/annotations/application/annotation_management_service.dart';
import 'package:kola/features/annotations/data/drift_annotation_repository.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/library/data/drift_document_repository.dart';

void main() {
  late KolaDatabase database;
  late DriftAnnotationRepository annotations;
  late DriftDocumentRepository documents;

  setUp(() {
    database = KolaDatabase(NativeDatabase.memory());
    annotations = DriftAnnotationRepository(database);
    documents = DriftDocumentRepository(database);
  });

  tearDown(() => database.close());

  test('note, color and tombstone persist through SQLite', () async {
    final DateTime createdAt = DateTime.utc(2026, 9, 12, 12);
    final DateTime update1 = DateTime.utc(2026, 9, 12, 12, 5);
    final DateTime update2 = DateTime.utc(2026, 9, 12, 12, 6);
    final DateTime deletedAt = DateTime.utc(2026, 9, 12, 12, 7);
    final List<DateTime> clockValues = <DateTime>[update1, update2, deletedAt];
    var clockIndex = 0;

    await documents.upsert(
      KolaDocument(
        id: 'doc-managed-annotation',
        source: DocumentSource(
          kind: DocumentSourceKind.linkedFile,
          uri: Uri.file('/tmp/managed.pdf'),
        ),
        format: DocumentFormat.pdf,
        metadata: const DocumentMetadata(title: 'Managed annotation'),
        importedAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    final Annotation original = Annotation(
      id: 'annotation-managed',
      documentId: 'doc-managed-annotation',
      type: AnnotationType.highlight,
      anchor: AnnotationAnchor(
        documentId: 'doc-managed-annotation',
        sourceLocator: DocumentLocation(
          scheme: 'pdf',
          data: const <String, Object?>{'page': 3, 'start': 1, 'end': 9},
          label: 'Page 3',
        ),
        exactQuote: 'important',
        sourceGeometry: const <Map<String, Object?>>[
          <String, Object?>{
            'scheme': 'pdf',
            'page': 3,
            'left': 11.0,
            'top': 44.0,
            'right': 58.0,
            'bottom': 30.0,
          },
        ],
      ),
      quote: 'important',
      colorToken: 'highlight.yellow',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    await annotations.upsert(original);

    final AnnotationManagementService service = AnnotationManagementService(
      annotations,
      clock: () => clockValues[clockIndex++],
    );

    final Annotation blue = await service.setHighlightColor(
      original,
      'highlight.blue',
    );
    final Annotation noted = await service.setNote(blue, 'Remember this');

    final Annotation? persisted = await annotations.getById(original.id);
    expect(persisted?.colorToken, 'highlight.blue');
    expect(persisted?.note, 'Remember this');
    expect(persisted?.revision, 3);
    expect(persisted?.anchor.sourceGeometry.single['left'], 11.0);
    expect((await annotations.watchForDocument(original.documentId).first), hasLength(1));

    await service.delete(noted);

    final Annotation? tombstone = await annotations.getById(original.id);
    expect(tombstone?.deletedAt, deletedAt);
    expect(tombstone?.revision, 4);
    expect(tombstone?.quote, 'important');
    expect(await annotations.watchForDocument(original.documentId).first, isEmpty);
  });
}
