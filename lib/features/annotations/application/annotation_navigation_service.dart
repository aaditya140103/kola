import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';

final class AnnotationNavigationService {
  const AnnotationNavigationService(this._formats);

  final FormatRegistry _formats;

  Future<AnchorResolution> resolve(
    KolaDocument document,
    Annotation annotation,
  ) async {
    if (annotation.documentId != document.id) {
      return const AnchorResolution.unresolved(
        reason: AnchorUnresolvedReason.documentMismatch,
      );
    }

    final DocumentAdapter? adapter = _formats.adapterFor(document.format);
    if (adapter == null) {
      return const AnchorResolution.unresolved(
        reason: AnchorUnresolvedReason.unsupportedFormat,
      );
    }

    final DocumentHandle handle = await adapter.open(document);
    try {
      return await adapter.resolveAnchor(handle, annotation.anchor);
    } finally {
      await handle.close();
    }
  }
}
