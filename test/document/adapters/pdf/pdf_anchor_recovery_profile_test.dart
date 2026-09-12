import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdf_anchor_recovery_profile.dart';
import 'package:kola/document/adapters/pdf/pdf_anchor_resolver.dart';
import 'package:kola/document/adapters/pdf/pdf_page_text_cache.dart';
import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/text/document_text_geometry.dart';

void main() {
  test('profiles stored-locator resolution without quote fallback', () async {
    PdfAnchorRecoveryProfile? profile;
    final PdfAnchorResolver resolver = PdfAnchorResolver(
      pageCount: 3,
      loadPageText: (int page) async => page == 2 ? 'prefix target suffix' : 'other',
      onProfile: (PdfAnchorRecoveryProfile value) => profile = value,
    );

    final AnchorResolution resolution = await resolver.resolve(
      _anchor(page: 2, start: 7, end: 13, quote: 'target'),
    );

    expect(resolution.resolved, isTrue);
    expect(resolution.strategy, AnchorResolutionStrategy.storedLocator);
    expect(profile, isNotNull);
    expect(profile!.pageLoadRequests, 1);
    expect(profile!.uniquePagesRequested, 1);
    expect(profile!.quoteSearchPagesScanned, 0);
    expect(profile!.quoteCandidatesFound, 0);
    expect(profile!.elapsed, isA<Duration>());
  });

  test('profiles full-document quote fallback', () async {
    const int pageCount = 300;
    PdfAnchorRecoveryProfile? profile;
    final PdfAnchorResolver resolver = PdfAnchorResolver(
      pageCount: pageCount,
      loadPageText: (int page) async =>
          page == pageCount ? 'before needle after' : 'page $page filler',
      onProfile: (PdfAnchorRecoveryProfile value) => profile = value,
    );

    final AnchorResolution resolution = await resolver.resolve(
      _anchor(page: 1, start: 0, end: 6, quote: 'needle'),
    );

    expect(resolution.resolved, isTrue);
    expect(resolution.strategy, AnchorResolutionStrategy.quoteContext);
    expect(profile!.pageLoadRequests, pageCount + 1);
    expect(profile!.uniquePagesRequested, pageCount);
    expect(profile!.quoteSearchPagesScanned, pageCount);
    expect(profile!.quoteCandidatesFound, 1);
  });

  test('synthetic heavy recovery quantifies scan cost after extraction caching', () async {
    const int pageCount = 200;
    const int annotationCount = 50;
    final PdfPageTextCache cache = PdfPageTextCache(
      (int page) async => _chunk(
        page,
        page == pageCount ? 'prefix common-target suffix' : 'page $page filler',
      ),
    );
    final List<PdfAnchorRecoveryProfile> profiles = <PdfAnchorRecoveryProfile>[];

    for (int i = 0; i < annotationCount; i += 1) {
      final PdfAnchorResolver resolver = PdfAnchorResolver(
        pageCount: pageCount,
        loadPageText: (int page) async => (await cache.get(page))!.text,
        onProfile: profiles.add,
      );
      final AnchorResolution resolution = await resolver.resolve(
        _anchor(page: 1, start: 0, end: 13, quote: 'common-target'),
      );
      expect(resolution.resolved, isTrue);
      expect(resolution.strategy, AnchorResolutionStrategy.quoteContext);
    }

    final PdfPageTextCacheSnapshot cacheStats = cache.snapshot;
    final int scannedPages = profiles.fold<int>(
      0,
      (int total, PdfAnchorRecoveryProfile profile) =>
          total + profile.quoteSearchPagesScanned,
    );

    // Extraction work is bounded by unique pages for the open-handle session.
    expect(cacheStats.misses, pageCount);
    expect(cacheStats.cachedPages, pageCount);
    expect(cacheStats.hits, greaterThan(0));

    // The current resolver still scans every page for every fallback recovery.
    // This baseline intentionally exposes the next optimization target.
    expect(scannedPages, annotationCount * pageCount);
    expect(profiles, hasLength(annotationCount));
  });
}

AnnotationAnchor _anchor({
  required int page,
  required int start,
  required int end,
  required String quote,
}) {
  return AnnotationAnchor(
    documentId: 'doc-1',
    sourceLocator: DocumentLocation(
      scheme: 'pdf',
      data: <String, Object?>{'page': page, 'start': start, 'end': end},
      label: 'Page $page',
    ),
    exactQuote: quote,
  );
}

DocumentTextChunk _chunk(int pageNumber, String text) {
  return DocumentTextChunk(
    documentId: 'doc-1',
    location: DocumentLocation(
      scheme: 'pdf',
      data: <String, Object?>{'page': pageNumber},
      label: 'Page $pageNumber',
    ),
    text: text,
    coordinateSpace: DocumentCoordinateSpace.pdfPagePoints,
    extentWidth: 600,
    extentHeight: 800,
    rotationDegrees: 0,
    characterBounds: const <DocumentRect>[],
    fragments: const <DocumentTextFragment>[],
  );
}
