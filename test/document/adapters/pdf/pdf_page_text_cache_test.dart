import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdf_page_text_cache.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/text/document_text_geometry.dart';

void main() {
  test('reuses one page extraction across repeated reads', () async {
    int loads = 0;
    final PdfPageTextCache cache = PdfPageTextCache((int pageNumber) async {
      loads += 1;
      return _chunk(pageNumber);
    });

    final DocumentTextChunk? first = await cache.get(4);
    final DocumentTextChunk? second = await cache.get(4);

    expect(first, same(second));
    expect(loads, 1);
    expect(cache.cachedPageCount, 1);
    expect(cache.snapshot.misses, 1);
    expect(cache.snapshot.hits, 1);
  });

  test('shares an in-flight extraction across concurrent reads', () async {
    int loads = 0;
    final Completer<DocumentTextChunk?> completer =
        Completer<DocumentTextChunk?>();
    final PdfPageTextCache cache = PdfPageTextCache((int pageNumber) {
      loads += 1;
      return completer.future;
    });

    final Future<DocumentTextChunk?> first = cache.get(7);
    final Future<DocumentTextChunk?> second = cache.get(7);
    expect(loads, 1);

    final DocumentTextChunk chunk = _chunk(7);
    completer.complete(chunk);

    expect(await first, same(chunk));
    expect(await second, same(chunk));
    expect(loads, 1);
    expect(cache.snapshot.misses, 1);
    expect(cache.snapshot.hits, 1);
  });

  test('caches pages independently', () async {
    int loads = 0;
    final PdfPageTextCache cache = PdfPageTextCache((int pageNumber) async {
      loads += 1;
      return _chunk(pageNumber);
    });

    await cache.get(1);
    await cache.get(2);
    await cache.get(1);

    expect(loads, 2);
    expect(cache.cachedPageCount, 2);
    expect(cache.snapshot.misses, 2);
    expect(cache.snapshot.hits, 1);
  });

  test('failed extraction is evicted so a later read can retry', () async {
    int loads = 0;
    final PdfPageTextCache cache = PdfPageTextCache((int pageNumber) async {
      loads += 1;
      if (loads == 1) throw StateError('temporary failure');
      return _chunk(pageNumber);
    });

    await expectLater(cache.get(3), throwsStateError);
    expect(cache.cachedPageCount, 0);
    expect(cache.snapshot.loadFailures, 1);

    final DocumentTextChunk? recovered = await cache.get(3);
    expect(recovered?.location.data['page'], 3);
    expect(loads, 2);
    expect(cache.cachedPageCount, 1);
    expect(cache.snapshot.misses, 2);
  });

  test('clear releases entries and resets diagnostics', () async {
    final PdfPageTextCache cache = PdfPageTextCache(
      (int pageNumber) async => _chunk(pageNumber),
    );

    await cache.get(1);
    await cache.get(2);
    await cache.get(1);
    expect(cache.cachedPageCount, 2);
    expect(cache.snapshot.hits, 1);
    expect(cache.snapshot.misses, 2);

    cache.clear();
    expect(cache.cachedPageCount, 0);
    expect(cache.snapshot.hits, 0);
    expect(cache.snapshot.misses, 0);
    expect(cache.snapshot.loadFailures, 0);
  });
}

DocumentTextChunk _chunk(int pageNumber) {
  return DocumentTextChunk(
    documentId: 'doc-1',
    location: DocumentLocation(
      scheme: 'pdf',
      data: <String, Object?>{'page': pageNumber},
      label: 'Page $pageNumber',
    ),
    text: 'Page $pageNumber text',
    coordinateSpace: DocumentCoordinateSpace.pdfPagePoints,
    extentWidth: 600,
    extentHeight: 800,
    rotationDegrees: 0,
    characterBounds: const <DocumentRect>[],
    fragments: const <DocumentTextFragment>[],
  );
}
