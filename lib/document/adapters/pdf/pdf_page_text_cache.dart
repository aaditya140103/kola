import 'package:kola/document/text/document_text_geometry.dart';

typedef PdfPageTextChunkLoader = Future<DocumentTextChunk?> Function(
  int pageNumber,
);

final class PdfPageTextCache {
  PdfPageTextCache(this._loader);

  final PdfPageTextChunkLoader _loader;
  final Map<int, Future<DocumentTextChunk?>> _entries =
      <int, Future<DocumentTextChunk?>>{};

  Future<DocumentTextChunk?> get(int pageNumber) async {
    final Future<DocumentTextChunk?>? cached = _entries[pageNumber];
    if (cached != null) return cached;

    final Future<DocumentTextChunk?> loading = _loader(pageNumber);
    _entries[pageNumber] = loading;
    try {
      return await loading;
    } catch (_) {
      _entries.remove(pageNumber);
      rethrow;
    }
  }

  void clear() => _entries.clear();

  int get cachedPageCount => _entries.length;
}
