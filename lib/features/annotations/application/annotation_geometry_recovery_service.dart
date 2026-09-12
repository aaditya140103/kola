import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/document/model/document_models.dart';

final class AnnotationGeometryRecoveryService {
  const AnnotationGeometryRecoveryService(this._formats);

  final FormatRegistry _formats;

  Future<Map<String, List<Map<String, Object?>>>> recover(
    KolaDocument document,
    List<Annotation> annotations,
  ) async {
    final DocumentAdapter? adapter = _formats.adapterFor(document.format);
    if (adapter == null || annotations.isEmpty) {
      return const <String, List<Map<String, Object?>>>{};
    }

    final DocumentHandle handle = await adapter.open(document);
    try {
      final List<Annotation> eligible = <Annotation>[
        for (final Annotation annotation in annotations)
          if (annotation.documentId == document.id &&
              annotation.type == AnnotationType.highlight)
            annotation,
      ];
      if (eligible.isEmpty) {
        return const <String, List<Map<String, Object?>>>{};
      }

      final List<AnnotationAnchor> anchors = <AnnotationAnchor>[
        for (final Annotation annotation in eligible) annotation.anchor,
      ];
      final List<AnchorResolution> resolutions;
      if (adapter is BatchAnchorResolver) {
        // Adapters with handle-scoped caches share one scanning pass across
        // the whole batch; behavior stays identical to per-anchor resolution.
        resolutions = await adapter.resolveAnchors(handle, anchors);
      } else {
        resolutions = <AnchorResolution>[
          for (final AnnotationAnchor anchor in anchors)
            await adapter.resolveAnchor(handle, anchor),
        ];
      }

      final Map<String, List<Map<String, Object?>>> result =
          <String, List<Map<String, Object?>>>{};
      for (int index = 0; index < eligible.length; index += 1) {
        if (index >= resolutions.length) break;
        final AnchorResolution resolution = resolutions[index];
        if (!resolution.resolved) continue;

        final List<Map<String, Object?>> geometry =
            resolution.sourceGeometry.isNotEmpty
            ? resolution.sourceGeometry
            : eligible[index].anchor.sourceGeometry;
        if (geometry.isNotEmpty) {
          result[eligible[index].id] = geometry;
        }
      }
      return Map<String, List<Map<String, Object?>>>.unmodifiable(result);
    } finally {
      await handle.close();
    }
  }
}
