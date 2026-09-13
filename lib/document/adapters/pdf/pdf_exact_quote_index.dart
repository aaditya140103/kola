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

final class PdfQuoteWarmUpResult {
  const PdfQuoteWarmUpResult({
    required this.warmedQuotes,
    required this.skippedQuotes,
    required this.pagesScanned,
  });

  final int warmedQuotes;
  final int skippedQuotes;
  final int pagesScanned;
}

final class PdfExactQuoteIndexSnapshot {
  const PdfExactQuoteIndexSnapshot({
    required this.hits,
    required this.misses,
    required this.failures,
    required this.cachedQuotes,
    required this.batchPagesScanned,
  });

  final int hits;
  final int misses;
  final int failures;
  final int cachedQuotes;
  final int batchPagesScanned;
}

/// Disposable, handle-scoped cache of exact-quote candidate positions.
///
/// The first lookup for a distinct quote scans the PDF page text once. Later
/// lookups for the same quote reuse the candidate positions while callers still
/// perform context verification against current page text.
///
/// [warmUp] collects candidates for many quotes with a single page-text pass
/// so batch recovery does not rescan every page once per distinct quote.
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
  int _batchPagesScanned = 0;

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

  /// Scans every page once for many quotes and caches their candidates.
  ///
  /// A transient multi-pattern automaton locates all occurrences of every
  /// pending quote in one pass over each page's text, producing exactly the
  /// candidates a per-quote [lookup] scan would find. Quotes that are empty,
  /// duplicates, or already cached are skipped without any page scan. A failed
  /// pass evicts only the quotes it was collecting so later lookups can retry.
  Future<PdfQuoteWarmUpResult> warmUp(Iterable<String> quotes) async {
    final List<String> pending = <String>[];
    final Set<String> seen = <String>{};
    int skippedQuotes = 0;
    for (final String quote in quotes) {
      if (quote.isEmpty || _entries.containsKey(quote) || !seen.add(quote)) {
        skippedQuotes += 1;
        continue;
      }
      pending.add(quote);
    }
    if (pending.isEmpty) {
      return PdfQuoteWarmUpResult(
        warmedQuotes: 0,
        skippedQuotes: skippedQuotes,
        pagesScanned: 0,
      );
    }

    final _AhoCorasickAutomaton automaton = _AhoCorasickAutomaton(pending);
    final Map<String, List<PdfQuoteCandidate>> collected =
        <String, List<PdfQuoteCandidate>>{
          for (final String quote in pending) quote: <PdfQuoteCandidate>[],
        };
    int pagesScanned = 0;
    try {
      for (int page = 1; page <= pageCount; page += 1) {
        pagesScanned += 1;
        _batchPagesScanned += 1;
        final String? text = await loadPageText(page);
        if (text == null || text.isEmpty) continue;
        automaton.scan(text, (int pattern, int start) {
          final String pendingQuote = pending[pattern];
          collected[pendingQuote]!.add(
            PdfQuoteCandidate(
              page: page,
              start: start,
              end: start + pendingQuote.length,
            ),
          );
        });
      }
    } catch (_) {
      for (final String quote in pending) {
        _entries.remove(quote);
      }
      rethrow;
    }

    for (final String quote in pending) {
      _entries[quote] = Future<List<PdfQuoteCandidate>>.value(
        List<PdfQuoteCandidate>.unmodifiable(collected[quote]!),
      );
    }
    return PdfQuoteWarmUpResult(
      warmedQuotes: pending.length,
      skippedQuotes: skippedQuotes,
      pagesScanned: pagesScanned,
    );
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
    _batchPagesScanned = 0;
  }

  PdfExactQuoteIndexSnapshot get snapshot => PdfExactQuoteIndexSnapshot(
    hits: _hits,
    misses: _misses,
    failures: _failures,
    cachedQuotes: _entries.length,
    batchPagesScanned: _batchPagesScanned,
  );
}

/// Code-unit Aho–Corasick automaton over a fixed set of literal patterns.
///
/// Matches the exact-substring semantics of `String.indexOf` scans, including
/// overlapping occurrences, and reports matches ordered by end offset within
/// each scanned text. Built per warm-up pass and discarded afterwards.
final class _AhoCorasickAutomaton {
  _AhoCorasickAutomaton(List<String> patterns) {
    patternLengths = <int>[
      for (final String pattern in patterns) pattern.length,
    ];
    _children.add(<int, int>{});
    _fails.add(_root);
    _outputs.add(<int>[]);
    for (int pattern = 0; pattern < patterns.length; pattern += 1) {
      int node = _root;
      for (final int unit in patterns[pattern].codeUnits) {
        final int? child = _children[node][unit];
        if (child == null) {
          _children.add(<int, int>{});
          _fails.add(_root);
          _outputs.add(<int>[]);
          final int created = _children.length - 1;
          _children[node][unit] = created;
          node = created;
        } else {
          node = child;
        }
      }
      _outputs[node].add(pattern);
    }

    final List<int> queue = <int>[..._children[_root].values];
    for (int head = 0; head < queue.length; head += 1) {
      final int node = queue[head];
      for (final MapEntry<int, int> edge in _children[node].entries) {
        final int unit = edge.key;
        final int child = edge.value;
        int fallback = _fails[node];
        while (fallback != _root && _children[fallback][unit] == null) {
          fallback = _fails[fallback];
        }
        final int? fallbackChild = _children[fallback][unit];
        if (fallbackChild == null || fallbackChild == child) {
          _fails[child] = _root;
        } else {
          _fails[child] = fallbackChild;
        }
        _outputs[child].addAll(_outputs[_fails[child]]);
        queue.add(child);
      }
    }
  }

  static const int _root = 0;

  late final List<int> patternLengths;
  final List<Map<int, int>> _children = <Map<int, int>>[];
  final List<int> _fails = <int>[];
  final List<List<int>> _outputs = <List<int>>[];

  void scan(String text, void Function(int pattern, int start) onMatch) {
    int node = _root;
    for (int index = 0; index < text.length; index += 1) {
      final int unit = text.codeUnitAt(index);
      while (node != _root && _children[node][unit] == null) {
        node = _fails[node];
      }
      final int? next = _children[node][unit];
      node = next ?? _root;
      final List<int> matches = _outputs[node];
      if (matches.isEmpty) continue;
      for (final int pattern in matches) {
        onMatch(pattern, index + 1 - patternLengths[pattern]);
      }
    }
  }
}
