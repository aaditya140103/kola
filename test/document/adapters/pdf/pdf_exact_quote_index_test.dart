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
  });
}
