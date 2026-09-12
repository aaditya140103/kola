import 'package:kola/document/text/document_text_geometry.dart';

typedef PdfPageTextChunkLoader = Future<DocumentTextChunk?> Function(
  int pageNumber,
);

final class PdfPageTextCache {
  PdfPageTextCache(this._loader);

  final PdfPageTextChunkLoader _loader;
  final Map<int, Future<DocumentTextChunk?>> _entries =
      <int, Future<DocumentTextChunk?>>{};

  Future<DocumentTextChunk?> get(int pageNumber) {
    return _entries.putIfAbsent(pageNumber, () => _loader(pageNumber));
  }

  void clear() => _entries.clear();

  int get cachedPageCount => _entries.length;
}
