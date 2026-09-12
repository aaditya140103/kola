import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdf_exact_quote_index.dart';

void main() {
  test('first lookup scans all pages and later lookup reuses candidates', () async {
    int pageLoads = 0;
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 4,
      loadPageText: (int page) async {
        pageLoads += 1;
        return switch (page) {
          2 => 'before target after',
          4 => 'target again',
          _ => 'page $page filler',
        };
      },
    );

    final PdfQuoteLookupResult first = await index.lookup('target');
    final PdfQuoteLookupResult second = await index.lookup('target');

    expect(first.cacheHit, isFalse);
    expect(first.pagesScanned, 4);
    expect(first.candidates, hasLength(2));
    expect(second.cacheHit, isTrue);
    expect(second.pagesScanned, 0);
    expect(second.candidates, hasLength(2));
    expect(pageLoads, 4);

    final PdfExactQuoteIndexSnapshot stats = index.snapshot;
    expect(stats.misses, 1);
    expect(stats.hits, 1);
    expect(stats.cachedQuotes, 1);
  });

  test('different quotes keep independent candidate entries', () async {
    int pageLoads = 0;
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 2,
      loadPageText: (int page) async {
        pageLoads += 1;
        return page == 1 ? 'alpha beta' : 'gamma beta';
      },
    );

    final PdfQuoteLookupResult alpha = await index.lookup('alpha');
    final PdfQuoteLookupResult beta = await index.lookup('beta');

    expect(alpha.candidates, hasLength(1));
    expect(beta.candidates, hasLength(2));
    expect(pageLoads, 4);
    expect(index.snapshot.misses, 2);
    expect(index.snapshot.cachedQuotes, 2);
  });

  test('shares one in-flight scan for concurrent same-quote lookups', () async {
    int pageLoads = 0;
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 3,
      loadPageText: (int page) async {
        pageLoads += 1;
        await Future<void>.delayed(Duration.zero);
        return page == 3 ? 'needle' : 'filler';
      },
    );

    final Future<PdfQuoteLookupResult> first = index.lookup('needle');
    final Future<PdfQuoteLookupResult> second = index.lookup('needle');
    final List<PdfQuoteLookupResult> results = await Future.wait(
      <Future<PdfQuoteLookupResult>>[first, second],
    );

    expect(results[0].cacheHit, isFalse);
    expect(results[1].cacheHit, isTrue);
    expect(results[0].candidates, hasLength(1));
    expect(results[1].candidates, hasLength(1));
    expect(pageLoads, 3);
  });

  test('failed scan is evicted so later lookup can retry', () async {
    int calls = 0;
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 1,
      loadPageText: (int page) async {
        calls += 1;
        if (calls == 1) throw StateError('temporary failure');
        return 'target';
      },
    );

    await expectLater(index.lookup('target'), throwsStateError);
    expect(index.snapshot.cachedQuotes, 0);
    expect(index.snapshot.failures, 1);

    final PdfQuoteLookupResult recovered = await index.lookup('target');
    expect(recovered.candidates, hasLength(1));
    expect(index.snapshot.misses, 2);
  });

  test('clear drops candidates and resets diagnostics', () async {
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 1,
      loadPageText: (int page) async => 'target',
    );

    await index.lookup('target');
    await index.lookup('target');
    index.clear();

    final PdfExactQuoteIndexSnapshot stats = index.snapshot;
    expect(stats.cachedQuotes, 0);
    expect(stats.hits, 0);
    expect(stats.misses, 0);
    expect(stats.failures, 0);
    expect(stats.batchPagesScanned, 0);
  });

  test('warm-up collects many quotes with one page pass', () async {
    int pageLoads = 0;
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 3,
      loadPageText: (int page) async {
        pageLoads += 1;
        return switch (page) {
          1 => 'alpha beta alpha',
          2 => null,
          3 => 'gamma beta',
        };
      },
    );

    final PdfQuoteWarmUpResult warmUp = await index.warmUp(<String>[
      'alpha',
      'beta',
      'gamma',
    ]);

    expect(warmUp.warmedQuotes, 3);
    expect(warmUp.skippedQuotes, 0);
    expect(warmUp.pagesScanned, 3);
    expect(pageLoads, 3);

    final PdfQuoteLookupResult alpha = await index.lookup('alpha');
    final PdfQuoteLookupResult beta = await index.lookup('beta');
    final PdfQuoteLookupResult gamma = await index.lookup('gamma');

    expect(alpha.cacheHit, isTrue);
    expect(alpha.pagesScanned, 0);
    expect(_keys(alpha.candidates), <String>['1:0-5', '1:11-16']);
    expect(beta.cacheHit, isTrue);
    expect(_keys(beta.candidates), <String>['1:6-10', '3:6-10']);
    expect(gamma.cacheHit, isTrue);
    expect(_keys(gamma.candidates), <String>['3:0-5']);

    final PdfExactQuoteIndexSnapshot stats = index.snapshot;
    expect(stats.hits, 3);
    expect(stats.misses, 0);
    expect(stats.cachedQuotes, 3);
    expect(stats.batchPagesScanned, 3);
  });

  test('warm-up matches per-quote scan candidates exactly', () async {
    const List<String> pages = <String>[
      'needle in the stack need',
      'no matches here',
      'needle needle needleneedle',
      '',
    ];
    const List<String> quotes = <String>[
      'needle',
      'need',
      'stack',
      'needle needle',
      'missing entirely',
    ];

    final PdfExactQuoteIndex scanned = PdfExactQuoteIndex(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page - 1],
    );
    final PdfExactQuoteIndex warmed = PdfExactQuoteIndex(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page - 1],
    );

    await warmed.warmUp(quotes);

    for (final String quote in quotes) {
      final PdfQuoteLookupResult perQuote = await scanned.lookup(quote);
      final PdfQuoteLookupResult batch = await warmed.lookup(quote);
      expect(_keys(batch.candidates), _keys(perQuote.candidates));
    }
  });

  test('warm-up finds overlapping occurrences like a per-quote scan', () async {
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 1,
      loadPageText: (int page) async => 'aaaaa',
    );

    await index.warmUp(<String>['aa', 'aaa']);

    expect(_keys((await index.lookup('aa')).candidates), <String>[
      '1:0-2',
      '1:1-3',
      '1:2-4',
      '1:3-5',
    ]);
    expect(_keys((await index.lookup('aaa')).candidates), <String>[
      '1:0-3',
      '1:1-4',
      '1:2-5',
    ]);
  });

  test('warm-up skips cached, duplicate, and empty quotes', () async {
    int pageLoads = 0;
    Future<String?> load(int page) async {
      pageLoads += 1;
      return page == 1 ? 'target beta' : 'page $page filler';
    }

    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 4,
      loadPageText: load,
    );

    await index.lookup('target');

    final PdfQuoteWarmUpResult warmUp = await index.warmUp(<String>[
      'target',
      'beta',
      'beta',
      '',
    ]);

    expect(warmUp.warmedQuotes, 1);
    expect(warmUp.skippedQuotes, 3);
    expect(warmUp.pagesScanned, 4);
    expect(pageLoads, 8);

    final PdfQuoteWarmUpResult again = await index.warmUp(<String>['target']);
    expect(again.warmedQuotes, 0);
    expect(again.skippedQuotes, 1);
    expect(again.pagesScanned, 0);
    expect(pageLoads, 8);
  });

  test('failed warm-up evicts only its quotes so lookups can retry', () async {
    bool failPageTwo = false;
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: 2,
      loadPageText: (int page) async {
        if (page == 2 && failPageTwo) throw StateError('temporary failure');
        return page == 1 ? 'target keep' : 'filler';
      },
    );

    await index.lookup('keep');

    failPageTwo = true;
    await expectLater(
      index.warmUp(<String>['target', 'keep']),
      throwsStateError,
    );

    expect(index.snapshot.cachedQuotes, 1);

    failPageTwo = false;
    final PdfQuoteLookupResult retry = await index.lookup('target');
    expect(retry.cacheHit, isFalse);
    expect(retry.candidates, hasLength(1));
    expect(index.snapshot.cachedQuotes, 2);
  });
}

List<String> _keys(List<PdfQuoteCandidate> candidates) {
  return <String>[
    for (final PdfQuoteCandidate candidate in candidates)
      '${candidate.page}:${candidate.start}-${candidate.end}',
  ];
}
