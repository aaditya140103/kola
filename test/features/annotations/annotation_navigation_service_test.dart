import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:kola/features/annotations/application/annotation_navigation_service.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';

void main() {
  test('returns adapter resolution and closes the handle', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      resolution: AnchorResolution.resolved(
        location: DocumentLocation(
          scheme: 'pdf',
          data: const <String, Object?>{'page': 7},
          label: 'Page 7',
        ),
        strategy: AnchorResolutionStrategy.quoteContext,
        confidence: 0.96,
      ),
    );
    final AnnotationNavigationService service = AnnotationNavigationService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );

    final AnchorResolution result = await service.resolve(
      _document(),
      _annotation(),
    );

    expect(result.resolved, isTrue);
    expect(result.location?.data['page'], 7);
    expect(result.strategy, AnchorResolutionStrategy.quoteContext);
    expect(adapter.openCount, 1);
    expect(adapter.handle.closed, isTrue);
  });

  test('preserves unresolved result and closes the handle', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      resolution: const AnchorResolution.unresolved(
        reason: 'Exact quote is ambiguous in the current document.',
      ),
    );
    final AnnotationNavigationService service = AnnotationNavigationService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );

    final AnchorResolution result = await service.resolve(
      _document(),
      _annotation(),
    );

    expect(result.resolved, isFalse);
    expect(result.reason, contains('ambiguous'));
    expect(adapter.handle.closed, isTrue);
  });

  test('document mismatch does not open an adapter', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      resolution: const AnchorResolution.unresolved(reason: 'unused'),
    );
    final AnnotationNavigationService service = AnnotationNavigationService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );
    final Annotation annotation = _annotation(documentId: 'other-document');

    final AnchorResolution result = await service.resolve(
      _document(),
      annotation,
    );

    expect(result.resolved, isFalse);
    expect(result.reason, contains('different document'));
    expect(adapter.openCount, 0);
  });

  test('closes the handle when adapter resolution throws', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      resolution: const AnchorResolution.unresolved(reason: 'unused'),
      throwOnResolve: true,
    );
    final AnnotationNavigationService service = AnnotationNavigationService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );

    await expectLater(
      service.resolve(_document(), _annotation()),
      throwsA(isA<StateError>()),
    );
    expect(adapter.handle.closed, isTrue);
  });
}

KolaDocument _document() {
  final DateTime now = DateTime.utc(2026, 9, 12);
  return KolaDocument(
    id: 'doc-1',
    source: DocumentSource(
      kind: DocumentSourceKind.linkedFile,
      uri: Uri.file('/tmp/anchor.pdf'),
    ),
    format: DocumentFormat.pdf,
    metadata: const DocumentMetadata(title: 'Anchor PDF'),
    importedAt: now,
    updatedAt: now,
  );
}

Annotation _annotation({String documentId = 'doc-1'}) {
  final DateTime now = DateTime.utc(2026, 9, 12);
  return Annotation(
    id: 'annotation-1',
    documentId: documentId,
    type: AnnotationType.highlight,
    anchor: AnnotationAnchor(
      documentId: documentId,
      sourceLocator: DocumentLocation(
        scheme: 'pdf',
        data: const <String, Object?>{'page': 3},
      ),
      exactQuote: 'recover me',
    ),
    quote: 'recover me',
    createdAt: now,
    updatedAt: now,
  );
}

final class _FakeAdapter implements DocumentAdapter {
  _FakeAdapter({required this.resolution, this.throwOnResolve = false});

  final AnchorResolution resolution;
  final bool throwOnResolve;
  final _FakeHandle handle = _FakeHandle('doc-1');
  int openCount = 0;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  FormatCapabilities get capabilities =>
      const FormatCapabilities(fidelityView: true, textAnnotations: true);

  @override
  Future<DocumentMetadata> readMetadata(DocumentSource source) async =>
      const DocumentMetadata(title: 'Fake');

  @override
  Future<DocumentHandle> open(KolaDocument document) async {
    openCount += 1;
    return handle;
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
  Stream<IndexChunk> extractIndexableContent(DocumentHandle handle) =>
      const Stream<IndexChunk>.empty();

  @override
  Future<AnchorResolution> resolveAnchor(
    DocumentHandle handle,
    AnnotationAnchor anchor,
  ) async {
    if (throwOnResolve) throw StateError('resolution failed');
    return resolution;
  }

  @override
  Future<ExportResult> export(ExportRequest request) {
    throw UnsupportedError('Not needed by this test.');
  }
}

final class _FakeHandle implements DocumentHandle {
  _FakeHandle(this.documentId);

  @override
  final String documentId;

  bool closed = false;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  Future<void> close() async {
    closed = true;
  }
}
