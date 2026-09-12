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

  test('one broken anchor does not suppress other recovered highlights', () async {
    const recoveredGeometry = <Map<String, Object?>>[
      <String, Object?>{'scheme': 'pdf', 'page': 3, 'left': 30.0},
    ];
    final adapter = _FakeAdapter(
      resolution: const AnchorResolution.unresolved(reason: 'unused'),
      resolutionFor: (AnnotationAnchor anchor) {
        if (anchor.exactQuote == 'broken') {
          throw StateError('malformed stale anchor');
        }
        return AnchorResolution.resolved(
          location: DocumentLocation(
            scheme: 'pdf',
            data: const <String, Object?>{'page': 3, 'start': 2, 'end': 7},
          ),
          strategy: AnchorResolutionStrategy.quoteContext,
          confidence: 0.96,
          sourceGeometry: recoveredGeometry,
        );
      },
    );
    final service = AnnotationGeometryRecoveryService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );

    final recovered = await service.recover(
      _document(),
      <Annotation>[
        _annotation(
          const <Map<String, Object?>>[{'page': 1}],
          id: 'broken-id',
          quote: 'broken',
        ),
        _annotation(
          const <Map<String, Object?>>[{'page': 1}],
          id: 'healthy-id',
          quote: 'healthy',
        ),
      ],
    );

    expect(recovered, <String, List<Map<String, Object?>>>{
      'healthy-id': recoveredGeometry,
    });
    expect(adapter.handle.closed, isTrue);
  });

  test('batch adapters receive eligible anchors once and stay zipped', () async {
    final adapter = _FakeBatchAdapter(
      resolutions: <AnchorResolution>[
        AnchorResolution.resolved(
          location: DocumentLocation(
            scheme: 'pdf',
            data: const <String, Object?>{'page': 9, 'start': 0, 'end': 5},
          ),
          strategy: AnchorResolutionStrategy.quoteContext,
          confidence: 0.96,
        ),
        const AnchorResolution.unresolved(reason: 'ambiguous'),
        AnchorResolution.resolved(
          location: DocumentLocation(
            scheme: 'pdf',
            data: const <String, Object?>{'page': 4, 'start': 1, 'end': 6},
          ),
          strategy: AnchorResolutionStrategy.quoteContext,
          confidence: 0.9,
        ),
      ],
    );
    final service = AnnotationGeometryRecoveryService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );

    final recovered = await service.recover(_document(), <Annotation>[
      _annotation(const <Map<String, Object?>>[{'page': 9}], id: 'a1'),
      _annotation(const <Map<String, Object?>>[], id: 'a2'),
      _annotation(const <Map<String, Object?>>[], id: 'a3'),
      _annotation(
        const <Map<String, Object?>>[],
        id: 'a4',
        documentId: 'other',
      ),
    ]);

    expect(adapter.batchCalls, 1);
    expect(adapter.singleCalls, 0);
    expect(adapter.requestedAnchors, hasLength(3));
    expect(adapter.requestedAnchors.map((a) => a.exactQuote), <String?>[
      'hello',
      'hello',
      'hello',
    ]);

    // a1 resolves without resolution geometry -> falls back to stored geometry.
    expect(recovered['a1'], const <Map<String, Object?>>[{'page': 9}]);
    // a2 is unresolved -> suppressed.
    expect(recovered.containsKey('a2'), isFalse);
    // a3 resolves but neither resolution nor anchor has geometry -> dropped.
    expect(recovered.containsKey('a3'), isFalse);
    // a4 belongs to another document -> filtered before the batch call.
    expect(recovered.containsKey('a4'), isFalse);
    expect(adapter.handle.closed, isTrue);
  });

  test('a failing batch adapter recovers nothing but still closes the handle', () async {
    final adapter = _FakeBatchAdapter(
      resolutions: const <AnchorResolution>[],
      throwOnBatch: true,
    );
    final service = AnnotationGeometryRecoveryService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );

    final recovered = await service.recover(
      _document(),
      <Annotation>[
        _annotation(const <Map<String, Object?>>[{'page': 9}], id: 'a1'),
      ],
    );

    expect(recovered, isEmpty);
    expect(adapter.handle.closed, isTrue);
  });

  test('non-batch adapters keep per-anchor resolution', () async {
    final adapter = _FakeAdapter(
      resolution: AnchorResolution.resolved(
        location: DocumentLocation(
          scheme: 'pdf',
          data: const <String, Object?>{'page': 2, 'start': 3, 'end': 8},
        ),
        strategy: AnchorResolutionStrategy.quoteContext,
        confidence: 0.96,
      ),
    );
    final service = AnnotationGeometryRecoveryService(
      FormatRegistry(<DocumentAdapter>[adapter]),
    );

    final recovered = await service.recover(_document(), <Annotation>[
      _annotation(const <Map<String, Object?>>[{'page': 2}], id: 'a1'),
      _annotation(const <Map<String, Object?>>[{'page': 2}], id: 'a2'),
    ]);

    expect(recovered.keys, unorderedEquals(<String>['a1', 'a2']));
    expect(adapter.resolveCalls, 2);
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

Annotation _annotation(
  List<Map<String, Object?>> geometry, {
  String id = 'a1',
  String quote = 'hello',
  String documentId = 'doc',
  AnnotationType type = AnnotationType.highlight,
}) {
  final now = DateTime.utc(2026, 9, 12);
  return Annotation(
    id: id,
    documentId: documentId,
    type: type,
    anchor: AnnotationAnchor(
      documentId: documentId,
      sourceLocator: DocumentLocation(
        scheme: 'pdf',
        data: const <String, Object?>{'page': 1, 'start': 0, 'end': 5},
      ),
      exactQuote: quote,
      sourceGeometry: geometry,
    ),
    createdAt: now,
    updatedAt: now,
  );
}

final class _FakeAdapter implements DocumentAdapter {
  _FakeAdapter({required this.resolution, this.resolutionFor});

  final AnchorResolution resolution;
  final AnchorResolution Function(AnnotationAnchor anchor)? resolutionFor;
  final _FakeHandle handle = _FakeHandle();
  int resolveCalls = 0;

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
  ) async {
    resolveCalls += 1;
    return resolutionFor?.call(anchor) ?? resolution;
  }

  @override
  Future<ExportResult> export(ExportRequest request) =>
      throw UnsupportedError('not needed');
}

final class _FakeBatchAdapter extends _FakeAdapter
    implements BatchAnchorResolver {
  _FakeBatchAdapter({required this.resolutions, this.throwOnBatch = false})
    : super(resolution: const AnchorResolution.unresolved(reason: 'unused'));

  final List<AnchorResolution> resolutions;
  final bool throwOnBatch;
  final List<AnnotationAnchor> requestedAnchors = <AnnotationAnchor>[];
  int batchCalls = 0;
  int singleCalls = 0;

  @override
  Future<List<AnchorResolution>> resolveAnchors(
    DocumentHandle handle,
    List<AnnotationAnchor> anchors,
  ) async {
    batchCalls += 1;
    if (throwOnBatch) {
      throw StateError('batch adapter failure');
    }
    requestedAnchors.addAll(anchors);
    return resolutions;
  }

  @override
  Future<AnchorResolution> resolveAnchor(
    DocumentHandle handle,
    AnnotationAnchor anchor,
  ) async {
    singleCalls += 1;
    return resolution;
  }
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
