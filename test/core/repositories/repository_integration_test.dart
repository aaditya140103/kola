import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/core/database/kola_database.dart'
    hide Annotation, PlannedReadingItem, ReadingCoverage, ReadingGoal, ReadingSession, ReadingState;
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/features/annotations/data/drift_annotation_repository.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/library/data/drift_document_repository.dart';
import 'package:kola/features/progress/data/drift_reading_repository.dart';
import 'package:kola/features/progress/domain/reading_models.dart';

void main() {
  late KolaDatabase database;
  late DriftDocumentRepository documents;
  late DriftReadingRepository reading;
  late DriftAnnotationRepository annotations;

  setUp(() {
    database = KolaDatabase(NativeDatabase.memory());
    documents = DriftDocumentRepository(database);
    reading = DriftReadingRepository(database);
    annotations = DriftAnnotationRepository(database);
  });

  tearDown(() => database.close());

  test('document writes invalidate the live library stream', () async {
    final DateTime now = DateTime.utc(2026, 9, 12, 10, 15, 30, 123, 456);
    final StreamIterator<List<KolaDocument>> iterator =
        StreamIterator<List<KolaDocument>>(
          documents.watchAll().timeout(const Duration(seconds: 5)),
        );

    try {
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isEmpty);

      await documents.upsert(
        KolaDocument(
          id: 'doc-1',
          source: DocumentSource(
            kind: DocumentSourceKind.linkedFile,
            uri: Uri.file('/tmp/example.epub'),
          ),
          format: DocumentFormat.epub,
          metadata: const DocumentMetadata(
            title: 'Example Book',
            authors: <String>['A. Reader'],
          ),
          importedAt: now,
          updatedAt: now,
        ),
      );

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current.single.id, 'doc-1');
    } finally {
      await iterator.cancel();
    }

    final KolaDocument? stored = await documents.getById('doc-1');
    expect(stored?.metadata.title, 'Example Book');
    expect(stored?.metadata.authors, <String>['A. Reader']);
    expect(stored?.importedAt.microsecond, now.microsecond);
  });

  test('reading list and sessions round-trip through the repository', () async {
    final DateTime now = DateTime.utc(2026, 9, 12, 11);
    await documents.upsert(
      KolaDocument(
        id: 'doc-2',
        source: DocumentSource(
          kind: DocumentSourceKind.managedCopy,
          uri: Uri.file('/library/book.pdf'),
        ),
        format: DocumentFormat.pdf,
        metadata: const DocumentMetadata(title: 'Stored PDF'),
        importedAt: now,
        updatedAt: now,
      ),
    );

    await reading.savePlannedItem(
      PlannedReadingItem(
        id: 'plan-1',
        linkedDocumentId: 'doc-2',
        title: 'Stored PDF',
        status: ReadingListStatus.nextUp,
        queuePosition: 1,
        addedAt: now,
        updatedAt: now,
      ),
    );
    await reading.saveSession(
      ReadingSession(
        id: 'session-1',
        documentId: 'doc-2',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 25)),
        activeTime: const Duration(minutes: 22),
        passiveTime: const Duration(minutes: 3),
        updatedAt: now.add(const Duration(minutes: 25)),
      ),
    );

    final List<PlannedReadingItem> list = await reading.watchReadingList().first;
    final List<ReadingSession> sessions = await reading.watchAllSessions().first;

    expect(list.single.status, ReadingListStatus.nextUp);
    expect(list.single.linkedDocumentId, 'doc-2');
    expect(sessions.single.activeTime, const Duration(minutes: 22));
  });

  test('annotation source anchors survive serialization', () async {
    final DateTime now = DateTime.utc(2026, 9, 12, 12);
    await documents.upsert(
      KolaDocument(
        id: 'doc-3',
        source: DocumentSource(
          kind: DocumentSourceKind.linkedFile,
          uri: Uri.file('/tmp/paper.pdf'),
        ),
        format: DocumentFormat.pdf,
        metadata: const DocumentMetadata(title: 'Paper'),
        importedAt: now,
        updatedAt: now,
      ),
    );

    await annotations.upsert(
      Annotation(
        id: 'annotation-1',
        documentId: 'doc-3',
        type: AnnotationType.highlight,
        anchor: AnnotationAnchor(
          documentId: 'doc-3',
          sourceLocator: DocumentLocation(
            scheme: 'pdf',
            data: const <String, Object?>{'page': 4, 'start': 12, 'end': 30},
            label: 'Page 5',
          ),
          exactQuote: 'source linked text',
          graphNodeIds: const <String>['paragraph-7'],
        ),
        quote: 'source linked text',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final Annotation? stored = await annotations.getById('annotation-1');
    expect(stored?.anchor.sourceLocator?.scheme, 'pdf');
    expect(stored?.anchor.sourceLocator?.data['page'], 4);
    expect(stored?.anchor.exactQuote, 'source linked text');
    expect(stored?.anchor.graphNodeIds, <String>['paragraph-7']);
  });
}
