import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdf_anchor_resolver.dart';
import 'package:kola/document/adapters/pdf/pdf_exact_quote_index.dart';
import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';

void main() {
  test('candidate index does not bypass ambiguity protection', () async {
    final Map<int, String> pages = <int, String>{
      1: 'prefix target suffix',
      2: 'prefix target suffix',
    };
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page],
    );
    final PdfAnchorResolver resolver = PdfAnchorResolver(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page],
      lookupQuoteCandidates: index.lookup,
    );

    final AnchorResolution result = await resolver.resolve(
      AnnotationAnchor(
        documentId: 'doc-1',
        sourceLocator: DocumentLocation(
          scheme: 'pdf',
          data: <String, Object?>{'page': 1, 'start': 0, 'end': 6},
          label: 'Page 1',
        ),
        exactQuote: 'target',
        prefixContext: 'prefix ',
        suffixContext: ' suffix',
      ),
    );

    expect(result.resolved, isFalse);
    expect(result.reason, contains('ambiguous'));
  });

  test('candidate index still uses context to distinguish matches', () async {
    final Map<int, String> pages = <int, String>{
      1: 'wrong target ending',
      2: 'before target after',
    };
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page],
    );
    final PdfAnchorResolver resolver = PdfAnchorResolver(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page],
      lookupQuoteCandidates: index.lookup,
    );

    final AnchorResolution result = await resolver.resolve(
      AnnotationAnchor(
        documentId: 'doc-1',
        sourceLocator: DocumentLocation(
          scheme: 'pdf',
          data: <String, Object?>{'page': 1, 'start': 0, 'end': 6},
          label: 'Page 1',
        ),
        exactQuote: 'target',
        prefixContext: 'before ',
        suffixContext: ' after',
      ),
    );

    expect(result.resolved, isTrue);
    expect(result.strategy, AnchorResolutionStrategy.quoteContext);
    expect(result.location?.data['page'], 2);
  });

  test('batch warm-up does not bypass ambiguity protection', () async {
    final Map<int, String> pages = <int, String>{
      1: 'prefix target suffix',
      2: 'prefix target suffix',
    };
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page],
    );
    await index.warmUp(<String>['target']);
    final PdfAnchorResolver resolver = PdfAnchorResolver(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page],
      lookupQuoteCandidates: index.lookup,
    );

    final AnchorResolution result = await resolver.resolve(
      AnnotationAnchor(
        documentId: 'doc-1',
        sourceLocator: DocumentLocation(
          scheme: 'pdf',
          data: <String, Object?>{'page': 1, 'start': 0, 'end': 6},
          label: 'Page 1',
        ),
        exactQuote: 'target',
        prefixContext: 'prefix ',
        suffixContext: ' suffix',
      ),
    );

    expect(result.resolved, isFalse);
    expect(result.reason, contains('ambiguous'));
  });

  test('batch warm-up still uses context to distinguish matches', () async {
    final Map<int, String> pages = <int, String>{
      1: 'wrong target ending',
      2: 'before target after',
    };
    final PdfExactQuoteIndex index = PdfExactQuoteIndex(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page],
    );
    await index.warmUp(<String>['target', 'unrelated']);
    final PdfAnchorResolver resolver = PdfAnchorResolver(
      pageCount: pages.length,
      loadPageText: (int page) async => pages[page],
      lookupQuoteCandidates: index.lookup,
    );

    final AnchorResolution result = await resolver.resolve(
      AnnotationAnchor(
        documentId: 'doc-1',
        sourceLocator: DocumentLocation(
          scheme: 'pdf',
          data: <String, Object?>{'page': 1, 'start': 0, 'end': 6},
          label: 'Page 1',
        ),
        exactQuote: 'target',
        prefixContext: 'before ',
        suffixContext: ' after',
      ),
    );

    expect(result.resolved, isTrue);
    expect(result.strategy, AnchorResolutionStrategy.quoteContext);
    expect(result.location?.data['page'], 2);
  });
}
