typedef PdfIndexedPageTextLoader = Future<String?> Function(int pageNumber);

final class PdfQuoteCandidate {
  const PdfQuoteCandidate({
    required this.page,
    required this.start,
    required this.end,
  });

  final int page;
  final int start;
  final int end;
}

final class PdfQuoteLookupResult {
  const PdfQuoteLookupResult({
    required this.candidates,
    required this.pagesScanned,
    required this.cacheHit,
  });

  final List<PdfQuoteCandidate> candidates;
  final int pagesScanned;
  final bool cacheHit;
}

final class PdfExactQuoteIndexSnapshot {
  const PdfExactQuoteIndexSnapshot({
    required this.hits,
    required this.misses,
    required this.failures,
    required this.cachedQuotes,
  });

  final int hits;
  final int misses;
  final int failures;
  final int cachedQuotes;
}

/// Disposable, handle-scoped cache of exact-quote candidate positions.
///
/// The first lookup for a distinct quote scans the PDF page text once. Later
/// lookups for the same quote reuse the candidate positions while callers still
/// perform context verification against current page text.
final class PdfExactQuoteIndex {
  PdfExactQuoteIndex({
    required this.pageCount,
    required this.loadPageText,
  });

  final int pageCount;
  final PdfIndexedPageTextLoader loadPageText;
  final Map<String, Future<List<PdfQuoteCandidate>>> _entries =
      <String, Future<List<PdfQuoteCandidate>>>{};

  int _hits = 0;
  int _misses = 0;
  int _failures = 0;

  Future<PdfQuoteLookupResult> lookup(String quote) async {
    if (quote.isEmpty) {
      return const PdfQuoteLookupResult(
        candidates: <PdfQuoteCandidate>[],
        pagesScanned: 0,
        cacheHit: true,
      );
    }

    final Future<List<PdfQuoteCandidate>>? cached = _entries[quote];
    if (cached != null) {
      _hits += 1;
      return PdfQuoteLookupResult(
        candidates: await cached,
        pagesScanned: 0,
        cacheHit: true,
      );
    }

    _misses += 1;
    final Future<List<PdfQuoteCandidate>> loading = _scan(quote);
    _entries[quote] = loading;
    try {
      return PdfQuoteLookupResult(
        candidates: await loading,
        pagesScanned: pageCount,
        cacheHit: false,
      );
    } catch (_) {
      _failures += 1;
      _entries.remove(quote);
      rethrow;
    }
  }

  Future<List<PdfQuoteCandidate>> _scan(String quote) async {
    final List<PdfQuoteCandidate> candidates = <PdfQuoteCandidate>[];
    for (int page = 1; page <= pageCount; page += 1) {
      final String? text = await loadPageText(page);
      if (text == null || text.isEmpty || text.length < quote.length) continue;

      int from = 0;
      while (from <= text.length - quote.length) {
        final int index = text.indexOf(quote, from);
        if (index < 0) break;
        candidates.add(
          PdfQuoteCandidate(
            page: page,
            start: index,
            end: index + quote.length,
          ),
        );
        from = index + 1;
      }
    }
    return List<PdfQuoteCandidate>.unmodifiable(candidates);
  }

  void clear() {
    _entries.clear();
    _hits = 0;
    _misses = 0;
    _failures = 0;
  }

  PdfExactQuoteIndexSnapshot get snapshot => PdfExactQuoteIndexSnapshot(
    hits: _hits,
    misses: _misses,
    failures: _failures,
    cachedQuotes: _entries.length,
  );
}
