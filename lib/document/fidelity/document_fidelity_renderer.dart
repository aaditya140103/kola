import 'package:flutter/widgets.dart';
import 'package:kola/document/model/document_models.dart';

abstract interface class DocumentFidelityRenderer {
  DocumentFormat get format;

  Widget build(BuildContext context, KolaDocument document);
}

final class FidelityRendererRegistry {
  FidelityRendererRegistry([
    Iterable<DocumentFidelityRenderer> renderers = const <DocumentFidelityRenderer>[],
  ]) {
    for (final DocumentFidelityRenderer renderer in renderers) {
      register(renderer);
    }
  }

  final Map<DocumentFormat, DocumentFidelityRenderer> _renderers =
      <DocumentFormat, DocumentFidelityRenderer>{};

  void register(DocumentFidelityRenderer renderer) {
    if (_renderers.containsKey(renderer.format)) {
      throw StateError(
        'A fidelity renderer is already registered for ${renderer.format.name}.',
      );
    }
    _renderers[renderer.format] = renderer;
  }

  DocumentFidelityRenderer? rendererFor(DocumentFormat format) =>
      _renderers[format];
}
