import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdf_anchor_resolver.dart';
import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';

void main() {
  group('PdfAnchorResolver', () {
    test('verifies an unchanged stored locator first', () async {
      const String page = 'Alpha beta gamma delta.';
      final PdfAnchorResolver resolver = _resolver(<int, String>{1: page});
      final AnnotationAnchor anchor = _anchor(
        page: 1,
        start: 6,
        end: 10,
        quote: 'beta',
        prefix: 'Alpha ',
        suffix: ' gamma',
      );

      final AnchorResolution result = await resolver.resolve(anchor);

      expect(result.resolved, isTrue);
      expect(result.strategy, AnchorResolutionStrategy.storedLocator);
      expect(result.confidence, 1.0);
      expect(result.location?.data['page'], 1);
      expect(result.location?.data['start'], 6);
    });

    test('recovers a shifted quote with prefix and suffix context', () async {
      final PdfAnchorResolver resolver = _resolver(<int, String>{
        1: 'Inserted text. Alpha beta gamma delta.',
      });
      final AnnotationAnchor anchor = _anchor(
        page: 1,
        start: 6,
        end: 10,
        quote: 'beta',
        prefix: 'Alpha ',
        suffix: ' gamma',
      );

      final AnchorResolution result = await resolver.resolve(anchor);

      expect(result.resolved, isTrue);
      expect(result.strategy, AnchorResolutionStrategy.quoteContext);
      expect(result.confidence, greaterThanOrEqualTo(0.9));
      expect(result.location?.data['start'], 21);
    });

    test('recovers when the quote moves to another page', () async {
      final PdfAnchorResolver resolver = _resolver(<int, String>{
        1: 'Nothing remains here.',
        2: 'Alpha beta gamma delta.',
      });
      final AnnotationAnchor anchor = _anchor(
        page: 1,
        start: 6,
        end: 10,
        quote: 'beta',
        prefix: 'Alpha ',
        suffix: ' gamma',
      );

      final AnchorResolution result = await resolver.resolve(anchor);

      expect(result.resolved, isTrue);
      expect(result.strategy, AnchorResolutionStrategy.quoteContext);
      expect(result.location?.data['page'], 2);
    });

    test('does not guess when the quote is ambiguous', () async {
      final PdfAnchorResolver resolver = _resolver(<int, String>{
        1: 'beta middle beta',
      });
      final AnnotationAnchor anchor = _anchor(
        page: 1,
        start: 99,
        end: 103,
        quote: 'beta',
      );

      final AnchorResolution result = await resolver.resolve(anchor);

      expect(result.resolved, isFalse);
      expect(result.reason, contains('ambiguous'));
    });

    test('returns unresolved when the exact quote is gone', () async {
      final PdfAnchorResolver resolver = _resolver(<int, String>{
        1: 'Alpha theta gamma delta.',
      });
      final AnnotationAnchor anchor = _anchor(
        page: 1,
        start: 6,
        end: 10,
        quote: 'beta',
      );

      final AnchorResolution result = await resolver.resolve(anchor);

      expect(result.resolved, isFalse);
      expect(result.reason, contains('not found'));
    });

    test('verifies stored multi-page fallback ranges', () async {
      final PdfAnchorResolver resolver = _resolver(<int, String>{
        1: 'Start first',
        2: 'second end',
      });
      final AnnotationAnchor anchor = AnnotationAnchor(
        documentId: 'doc',
        sourceLocator: DocumentLocation(
          scheme: 'pdf',
          data: <String, Object?>{
            'page': 1,
            'start': 6,
            'end': 11,
            'endPage': 2,
          },
        ),
        exactQuote: 'first\nsecond',
        prefixContext: 'Start ',
        suffixContext: ' end',
        formatSpecificFallback: <String, Object?>{
          'ranges': <Map<String, Object?>>[
            <String, Object?>{'page': 1, 'start': 6, 'end': 11},
            <String, Object?>{'page': 2, 'start': 0, 'end': 6},
          ],
        },
      );

      final AnchorResolution result = await resolver.resolve(anchor);

      expect(result.resolved, isTrue);
      expect(result.strategy, AnchorResolutionStrategy.storedLocator);
      expect(result.confidence, 0.99);
      expect(result.location?.data['page'], 1);
    });
  });
}

PdfAnchorResolver _resolver(Map<int, String> pages) {
  return PdfAnchorResolver(
    pageCount: pages.length,
    loadPageText: (int page) async => pages[page],
  );
}

AnnotationAnchor _anchor({
  required int page,
  required int start,
  required int end,
  required String quote,
  String? prefix,
  String? suffix,
}) {
  return AnnotationAnchor(
    documentId: 'doc',
    sourceLocator: DocumentLocation(
      scheme: 'pdf',
      data: <String, Object?>{
        'page': page,
        'start': start,
        'end': end,
      },
    ),
    exactQuote: quote,
    prefixContext: prefix,
    suffixContext: suffix,
    logicalStart: start,
    logicalEnd: end,
  );
}
