import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/core/database/kola_database.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/library/data/drift_document_repository.dart';
import 'package:kola/features/search/data/drift_search_repository.dart';
import 'package:kola/features/search/domain/search_models.dart';

void main() {
  late KolaDatabase database;
  late DriftDocumentRepository documents;
  late DriftSearchRepository search;

  setUp(() {
    database = KolaDatabase(NativeDatabase.memory());
    documents = DriftDocumentRepository(database);
    search = DriftSearchRepository(database);
  });

  tearDown(() => database.close());

  test('persists page-level content and metadata in FTS5', () async {
    final KolaDocument document = _document(revision: 3);
    await documents.upsert(document);
    await search.replaceDocumentIndex(
      document: document,
      extractorVersion: 'test-v1',
      chunks: <IndexChunk>[
        IndexChunk(
          documentId: document.id,
          text: 'Transformers use attention to mix information across tokens.',
          location: DocumentLocation(
            scheme: 'pdf',
            data: const <String, Object?>{'page': 7},
            label: 'Page 7',
          ),
          sectionLabel: 'Page 7',
        ),
      ],
    );

    final status = await search.getIndexStatus(document.id);
    expect(status?.indexedRevision, 3);
    expect(status?.extractorVersion, 'test-v1');

    final List<SearchHit> content = await search.search(
      'attention',
      documentId: document.id,
      kind: SearchHitKind.content,
    );
    expect(content, hasLength(1));
    expect(content.single.documentId, document.id);
    expect(content.single.pageNumber, 7);
    expect(content.single.kind, SearchHitKind.content);
    expect(content.single.snippet.toLowerCase(), contains('attention'));

    final List<SearchHit> metadata = await search.search('Architecture');
    expect(metadata, isNotEmpty);
    expect(
      metadata.any((SearchHit hit) => hit.kind == SearchHitKind.metadata),
      isTrue,
    );
  });

  test('document deletion removes search state and FTS rows', () async {
    final KolaDocument document = _document();
    await documents.upsert(document);
    await search.replaceDocumentIndex(
      document: document,
      extractorVersion: 'test-v1',
      chunks: <IndexChunk>[
        IndexChunk(
          documentId: document.id,
          text: 'local private search content',
          location: DocumentLocation(
            scheme: 'pdf',
            data: const <String, Object?>{'page': 2},
          ),
        ),
      ],
    );

    expect(await search.search('private'), isNotEmpty);
    await documents.remove(document.id);

    expect(await search.getIndexStatus(document.id), isNull);
    expect(await search.search('private'), isEmpty);
  });
}

KolaDocument _document({int revision = 1}) {
  final DateTime now = DateTime.utc(2026, 9, 12, 10);
  return KolaDocument(
    id: 'sha256:search-test',
    contentHash: 'sha256:search-test',
    source: DocumentSource(
      kind: DocumentSourceKind.linkedFile,
      uri: Uri.file('/tmp/search-test.pdf'),
    ),
    format: DocumentFormat.pdf,
    metadata: const DocumentMetadata(
      title: 'GPU Architecture Handbook',
      authors: <String>['A. Reader'],
    ),
    importedAt: now,
    updatedAt: now,
    revision: revision,
  );
}
