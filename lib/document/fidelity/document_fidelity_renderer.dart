import 'package:flutter/widgets.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/text/document_text_selection.dart';

final class FidelityViewState {
  const FidelityViewState({
    required this.positionProgress,
    required this.zoom,
    this.location,
  });

  final DocumentLocation? location;
  final double positionProgress;
  final double zoom;
}

final class FidelityNavigationRequest {
  const FidelityNavigationRequest({
    required this.location,
    required this.sequence,
  });

  final DocumentLocation location;
  final int sequence;
}

abstract interface class DocumentFidelityRenderer {
  DocumentFormat get format;

  Widget build(
    BuildContext context,
    KolaDocument document, {
    FidelityViewState? initialState,
    FidelityNavigationRequest? navigationRequest,
    ValueChanged<FidelityViewState>? onStateChanged,
    ValueChanged<DocumentTextSelection>? onTextSelection,
    List<FidelityTextHighlight> highlights = const <FidelityTextHighlight>[],
  });
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
