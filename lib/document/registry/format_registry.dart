import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';

final class FormatRegistry {
  FormatRegistry([Iterable<DocumentAdapter> adapters = const <DocumentAdapter>[]]) {
    for (final DocumentAdapter adapter in adapters) {
      register(adapter);
    }
  }

  final Map<DocumentFormat, DocumentAdapter> _adapters =
      <DocumentFormat, DocumentAdapter>{};

  Iterable<DocumentFormat> get registeredFormats => _adapters.keys;

  void register(DocumentAdapter adapter) {
    final DocumentAdapter? existing = _adapters[adapter.format];
    if (existing != null) {
      throw StateError(
        'A DocumentAdapter is already registered for ${adapter.format.name}.',
      );
    }
    _adapters[adapter.format] = adapter;
  }

  DocumentAdapter? adapterFor(DocumentFormat format) => _adapters[format];

  FormatCapabilities? capabilitiesFor(DocumentFormat format) =>
      _adapters[format]?.capabilities;
}
