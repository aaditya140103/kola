import 'package:kola/document/text/document_text_geometry.dart';

typedef PdfPageTextChunkLoader = Future<DocumentTextChunk?> Function(
  int pageNumber,
);

final class PdfPageTextCacheSnapshot {
  const PdfPageTextCacheSnapshot({
    required this.hits,
    required this.misses,
    required this.loadFailures,
    required this.cachedPages,
  });

  final int hits;
  final int misses;
  final int loadFailures;
  final int cachedPages;
}

final class PdfPageTextCache {
  PdfPageTextCache(this._loader);

  final PdfPageTextChunkLoader _loader;
  final Map<int, Future<DocumentTextChunk?>> _entries =
      <int, Future<DocumentTextChunk?>>{};

  int _hits = 0;
  int _misses = 0;
  int _loadFailures = 0;

  Future<DocumentTextChunk?> get(int pageNumber) async {
    final Future<DocumentTextChunk?>? cached = _entries[pageNumber];
    if (cached != null) {
      _hits += 1;
      return cached;
    }

    _misses += 1;
    final Future<DocumentTextChunk?> loading = _loader(pageNumber);
    _entries[pageNumber] = loading;
    try {
      return await loading;
    } catch (_) {
      _loadFailures += 1;
      _entries.remove(pageNumber);
      rethrow;
    }
  }

  PdfPageTextCacheSnapshot get snapshot => PdfPageTextCacheSnapshot(
    hits: _hits,
    misses: _misses,
    loadFailures: _loadFailures,
    cachedPages: _entries.length,
  );

  void clear() {
    _entries.clear();
    _hits = 0;
    _misses = 0;
    _loadFailures = 0;
  }

  int get cachedPageCount => _entries.length;
}
