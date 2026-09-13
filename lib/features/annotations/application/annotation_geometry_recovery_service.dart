import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';

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
      if (adapter case final BatchAnchorResolver batchAdapter) {
        // Adapters with handle-scoped caches share one scanning pass across
        // the whole batch; behavior stays identical to per-anchor resolution.
        resolutions = await _resolveBatch(batchAdapter, handle, anchors);
      } else {
        resolutions = <AnchorResolution>[
          for (final AnnotationAnchor anchor in anchors)
            await _resolveIsolated(adapter, handle, anchor),
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

  static Future<List<AnchorResolution>> _resolveBatch(
    BatchAnchorResolver adapter,
    DocumentHandle handle,
    List<AnnotationAnchor> anchors,
  ) async {
    // Batch recovery stays best-effort: an adapter-level failure must not
    // break the app, matching the per-anchor isolation of the fallback path.
    try {
      return await adapter.resolveAnchors(handle, anchors);
    } catch (_) {
      return const <AnchorResolution>[];
    }
  }

  static Future<AnchorResolution> _resolveIsolated(
    DocumentAdapter adapter,
    DocumentHandle handle,
    AnnotationAnchor anchor,
  ) async {
    // Recovery is best-effort per annotation. One malformed/stale anchor
    // must not suppress every other valid highlight in the document.
    try {
      return await adapter.resolveAnchor(handle, anchor);
    } catch (_) {
      return const AnchorResolution.unresolved(
        reason: 'Annotation anchor recovery failed.',
      );
    }
  }
}
