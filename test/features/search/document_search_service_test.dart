import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/core/database/kola_database.dart';
import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:kola/features/library/data/drift_document_repository.dart';
import 'package:kola/features/search/application/document_search_service.dart';
import 'package:kola/features/search/data/drift_search_repository.dart';
import 'package:kola/features/search/domain/search_models.dart';

void main() {
  late KolaDatabase database;
  late DriftDocumentRepository documents;
  late DriftSearchRepository search;
  late _FakeTextAdapter adapter;
  late DocumentSearchService service;

  setUp(() {
    database = KolaDatabase(NativeDatabase.memory());
    documents = DriftDocumentRepository(database);
    search = DriftSearchRepository(database);
    adapter = _FakeTextAdapter();
    service = DocumentSearchService(
      documents: documents,
      search: search,
      formats: FormatRegistry(<DocumentAdapter>[adapter]),
    );
  });

  tearDown(() => database.close());

  test('indexes lazily and reuses a current persistent index', () async {
    final KolaDocument document = _document(revision: 1);
    await documents.upsert(document);

    final first = await service.searchDocument(document, 'needle');
    expect(first, hasLength(1));
    expect(first.single.pageNumber, 3);
    expect(adapter.openCount, 1);

    final second = await service.searchDocument(document, 'needle');
    expect(second, hasLength(1));
    expect(adapter.openCount, 1);
  });

  test('reindexes when the document revision changes', () async {
    final KolaDocument firstRevision = _document(revision: 1);
    await documents.upsert(firstRevision);
    await service.searchDocument(firstRevision, 'needle');
    expect(adapter.openCount, 1);

    final KolaDocument secondRevision = _document(revision: 2);
    await documents.upsert(secondRevision);
    await service.searchDocument(secondRevision, 'needle');
    expect(adapter.openCount, 2);
  });

  test('newer revision waits for older in-flight indexing and wins', () async {
    final Completer<void> releaseRevisionOne = Completer<void>();
    adapter.revisionOneGate = releaseRevisionOne;

    final KolaDocument firstRevision = _document(revision: 1);
    await documents.upsert(firstRevision);
    final Future<void> first = service.ensureIndexed(firstRevision);
    await adapter.revisionOneExtractionStarted.future;

    final KolaDocument secondRevision = _document(revision: 2);
    await documents.upsert(secondRevision);
    final Future<void> second = service.ensureIndexed(secondRevision);

    expect(adapter.openCount, 1);
    releaseRevisionOne.complete();
    await Future.wait(<Future<void>>[first, second]);

    final SearchIndexStatus? status = await search.getIndexStatus(
      secondRevision.id,
    );
    expect(status?.indexedRevision, 2);
    expect(adapter.openCount, 2);
  });

  test('stale revision cannot downgrade a newer persistent index', () async {
    final KolaDocument secondRevision = _document(revision: 2);
    await documents.upsert(secondRevision);
    await service.ensureIndexed(secondRevision);
    expect(adapter.openCount, 1);

    await service.ensureIndexed(_document(revision: 1));

    final SearchIndexStatus? status = await search.getIndexStatus(
      secondRevision.id,
    );
    expect(status?.indexedRevision, 2);
    expect(adapter.openCount, 1);
  });
}

KolaDocument _document({required int revision}) {
  final DateTime now = DateTime.utc(2026, 9, 12, 10);
  return KolaDocument(
    id: 'sha256:lazy-index',
    source: DocumentSource(
      kind: DocumentSourceKind.linkedFile,
      uri: Uri.file('/tmp/lazy-index.pdf'),
    ),
    format: DocumentFormat.pdf,
    metadata: DocumentMetadata(title: 'Lazy Index r$revision'),
    importedAt: now,
    updatedAt: now,
    revision: revision,
  );
}

final class _FakeTextAdapter implements DocumentAdapter {
  int openCount = 0;
  Completer<void>? revisionOneGate;
  final Completer<void> revisionOneExtractionStarted = Completer<void>();

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  FormatCapabilities get capabilities =>
      const FormatCapabilities(fidelityView: true, textSearch: true);

  @override
  Future<DocumentMetadata> readMetadata(DocumentSource source) async =>
      const DocumentMetadata(title: 'Fake PDF');

  @override
  Future<DocumentHandle> open(KolaDocument document) async {
    openCount += 1;
    return _FakeHandle(document.id, document.revision);
  }

  @override
  Future<FidelityDescriptor?> buildFidelityView(DocumentHandle handle) async =>
      const FidelityDescriptor(kind: FidelitySurfaceKind.pdfPages);

  @override
  Stream<DocumentTextChunk> extractTextGeometry(DocumentHandle handle) =>
      const Stream<DocumentTextChunk>.empty();

  @override
  Stream<GraphChunk> buildDocumentGraph(
    DocumentHandle handle,
    GraphBuildOptions options,
  ) => const Stream<GraphChunk>.empty();

  @override
  Stream<IndexChunk> extractIndexableContent(DocumentHandle handle) async* {
    final _FakeHandle fakeHandle = handle as _FakeHandle;
    final Completer<void>? gate = revisionOneGate;
    if (fakeHandle.revision == 1 && gate != null) {
      if (!revisionOneExtractionStarted.isCompleted) {
        revisionOneExtractionStarted.complete();
      }
      await gate.future;
    }

    yield IndexChunk(
      documentId: handle.documentId,
      text: 'There is a needle inside revision ${fakeHandle.revision}.',
      location: DocumentLocation(
        scheme: 'pdf',
        data: const <String, Object?>{'page': 3},
        label: 'Page 3',
      ),
      sectionLabel: 'Page 3',
    );
  }

  @override
  Future<AnchorResolution> resolveAnchor(
    DocumentHandle handle,
    AnnotationAnchor anchor,
  ) async {
    final DocumentLocation? location = anchor.sourceLocator;
    if (location == null) {
      return const AnchorResolution.unresolved(
        reason: 'Fake adapter has no source locator.',
      );
    }
    return AnchorResolution.resolved(
      location: location,
      strategy: AnchorResolutionStrategy.storedLocator,
      confidence: 1.0,
    );
  }

  @override
  Future<ExportResult> export(ExportRequest request) {
    throw UnsupportedError('Not needed by this test.');
  }
}

final class _FakeHandle implements DocumentHandle {
  const _FakeHandle(this.documentId, this.revision);

  @override
  final String documentId;

  final int revision;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  Future<void> close() async {}
}
