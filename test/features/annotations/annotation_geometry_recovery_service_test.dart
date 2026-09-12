import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:kola/features/annotations/application/annotation_geometry_recovery_service.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';

void main() {
  test('uses recovered geometry without mutating the stored anchor', () async {
    const oldGeometry = <Map<String, Object?>>[
      <String, Object?>{'scheme': 'pdf', 'page': 1, 'left': 1.0},
    ];
    const newGeometry = <Map<String, Object?>>[
      <String, Object?>{'scheme': 'pdf', 'page': 2, 'left': 20.0},
    ];
    final adapter = _FakeAdapter(
      resolution: AnchorResolution.resolved(
        location: DocumentLocation(
          scheme: 'pdf',
          data: const <String, Object?>{'page': 2, 'start': 3, 'end': 8},
        ),
        strategy: AnchorResolutionStrategy.quoteContext,
        confidence: 0.96,
        sourceGeometry: newGeometry,
      ),
    );
    final service = AnnotationGeometryRecoveryService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );
    final annotation = _annotation(oldGeometry);

    final recovered = await service.recover(_document(), <Annotation>[annotation]);

    expect(recovered['a1'], newGeometry);
    expect(annotation.anchor.sourceGeometry, oldGeometry);
    expect(adapter.handle.closed, isTrue);
  });

  test('suppresses unresolved stale geometry', () async {
    final adapter = _FakeAdapter(
      resolution: const AnchorResolution.unresolved(reason: 'ambiguous'),
    );
    final service = AnnotationGeometryRecoveryService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );

    final recovered = await service.recover(
      _document(),
      <Annotation>[_annotation(const <Map<String, Object?>>[{'page': 1}])],
    );

    expect(recovered, isEmpty);
    expect(adapter.handle.closed, isTrue);
  });
}

KolaDocument _document() {
  final now = DateTime.utc(2026, 9, 12);
  return KolaDocument(
    id: 'doc',
    source: DocumentSource(
      kind: DocumentSourceKind.linkedFile,
      uri: Uri.file('/tmp/doc.pdf'),
    ),
    format: DocumentFormat.pdf,
    metadata: const DocumentMetadata(title: 'Doc'),
    importedAt: now,
    updatedAt: now,
  );
}

Annotation _annotation(List<Map<String, Object?>> geometry) {
  final now = DateTime.utc(2026, 9, 12);
  return Annotation(
    id: 'a1',
    documentId: 'doc',
    type: AnnotationType.highlight,
    anchor: AnnotationAnchor(
      documentId: 'doc',
      sourceLocator: DocumentLocation(
        scheme: 'pdf',
        data: const <String, Object?>{'page': 1, 'start': 0, 'end': 5},
      ),
      exactQuote: 'hello',
      sourceGeometry: geometry,
    ),
    createdAt: now,
    updatedAt: now,
  );
}

final class _FakeAdapter implements DocumentAdapter {
  _FakeAdapter({required this.resolution});

  final AnchorResolution resolution;
  final _FakeHandle handle = _FakeHandle();

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  FormatCapabilities get capabilities =>
      const FormatCapabilities(fidelityView: true, textAnnotations: true);

  @override
  Future<DocumentMetadata> readMetadata(DocumentSource source) async =>
      const DocumentMetadata(title: 'Doc');

  @override
  Future<DocumentHandle> open(KolaDocument document) async => handle;

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
  ) async => resolution;

  @override
  Future<ExportResult> export(ExportRequest request) =>
      throw UnsupportedError('not needed');
}

final class _FakeHandle implements DocumentHandle {
  bool closed = false;

  @override
  String get documentId => 'doc';

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  Future<void> close() async {
    closed = true;
  }
}
