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
      final Map<String, List<Map<String, Object?>>> result =
          <String, List<Map<String, Object?>>>{};
      for (final Annotation annotation in annotations) {
        if (annotation.documentId != document.id ||
            annotation.type != AnnotationType.highlight) {
          continue;
        }

        // Recovery is best-effort per annotation. One malformed/stale anchor
        // must not suppress every other valid highlight in the document.
        try {
          final resolution = await adapter.resolveAnchor(
            handle,
            annotation.anchor,
          );
          if (!resolution.resolved) continue;

          final List<Map<String, Object?>> geometry =
              resolution.sourceGeometry.isNotEmpty
              ? resolution.sourceGeometry
              : annotation.anchor.sourceGeometry;
          if (geometry.isNotEmpty) {
            result[annotation.id] = geometry;
          }
        } catch (_) {
          continue;
        }
      }
      return Map<String, List<Map<String, Object?>>>.unmodifiable(result);
    } finally {
      await handle.close();
    }
  }
}
