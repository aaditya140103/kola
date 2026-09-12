import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';

typedef PdfPageTextLoader = Future<String?> Function(int pageNumber);
typedef PdfRangeGeometryLoader = Future<List<Map<String, Object?>>> Function(
  int pageNumber,
  int start,
  int end,
);

final class PdfAnchorResolver {
  const PdfAnchorResolver({
    required this.pageCount,
    required this.loadPageText,
    this.loadRangeGeometry,
  });

  final int pageCount;
  final PdfPageTextLoader loadPageText;
  final PdfRangeGeometryLoader? loadRangeGeometry;

  Future<AnchorResolution> resolve(AnnotationAnchor anchor) async {
    final DocumentLocation? locator = anchor.sourceLocator;
    if (locator == null || locator.scheme != 'pdf') {
      return const AnchorResolution.unresolved(
        reason: 'Anchor has no PDF source locator.',
      );
    }

    final String quote = anchor.exactQuote ?? '';
    if (quote.isEmpty) {
      return const AnchorResolution.unresolved(
        reason: 'Anchor has no exact quote to verify.',
      );
    }

    final AnchorResolution? fallbackRangeResolution =
        await _verifyFallbackRanges(anchor, quote);
    if (fallbackRangeResolution != null) return fallbackRangeResolution;

    final int? locatorPage = _asInt(locator.data['page']);
    final int? locatorStart = _asInt(locator.data['start']);
    final int? locatorEnd = _asInt(locator.data['end']);

    if (locatorPage != null && locatorStart != null && locatorEnd != null) {
      final String? pageText = await _safeLoad(locatorPage);
      if (_rangeMatches(pageText, locatorStart, locatorEnd, quote)) {
        return _resolved(
          page: locatorPage,
          start: locatorStart,
          end: locatorEnd,
          strategy: AnchorResolutionStrategy.storedLocator,
          confidence: 1.0,
        );
      }
    }

    if (locatorPage != null &&
        anchor.logicalStart != null &&
        anchor.logicalEnd != null) {
      final String? pageText = await _safeLoad(locatorPage);
      if (_rangeMatches(
        pageText,
        anchor.logicalStart!,
        anchor.logicalEnd!,
        quote,
      )) {
        return _resolved(
          page: locatorPage,
          start: anchor.logicalStart!,
          end: anchor.logicalEnd!,
          strategy: AnchorResolutionStrategy.logicalRange,
          confidence: 0.98,
        );
      }
    }

    final List<_QuoteCandidate> candidates = <_QuoteCandidate>[];
    for (int page = 1; page <= pageCount; page += 1) {
      final String? text = await _safeLoad(page);
      if (text == null || text.isEmpty) continue;

      int from = 0;
      while (from <= text.length - quote.length) {
        final int index = text.indexOf(quote, from);
        if (index < 0) break;
        final int end = index + quote.length;
        candidates.add(
          _QuoteCandidate(
            page: page,
            start: index,
            end: end,
            contextScore: _contextScore(
              text,
              index,
              end,
              anchor.prefixContext,
              anchor.suffixContext,
            ),
          ),
        );
        from = index + 1;
      }
    }

    if (candidates.isEmpty) {
      return const AnchorResolution.unresolved(
        reason: 'Exact quote was not found in the current PDF text.',
      );
    }

    candidates.sort(
      (_QuoteCandidate a, _QuoteCandidate b) =>
          b.contextScore.compareTo(a.contextScore),
    );

    final _QuoteCandidate best = candidates.first;
    if (candidates.length > 1 &&
        candidates[1].contextScore == best.contextScore) {
      return const AnchorResolution.unresolved(
        reason: 'Exact quote is ambiguous in the current PDF.',
      );
    }

    final double confidence = switch (best.contextScore) {
      >= 2 => 0.96,
      1 => 0.90,
      _ => candidates.length == 1 ? 0.82 : 0.0,
    };
    if (confidence == 0.0) {
      return const AnchorResolution.unresolved(
        reason: 'Quote matches are not distinguishable with stored context.',
      );
    }

    return _resolved(
      page: best.page,
      start: best.start,
      end: best.end,
      strategy: AnchorResolutionStrategy.quoteContext,
      confidence: confidence,
    );
  }

  Future<AnchorResolution?> _verifyFallbackRanges(
    AnnotationAnchor anchor,
    String quote,
  ) async {
    final Object? raw = anchor.formatSpecificFallback['ranges'];
    if (raw is! List || raw.length < 2) return null;

    final List<_StoredRange> ranges = <_StoredRange>[];
    for (final Object? item in raw) {
      if (item is! Map) return null;
      final int? page = _asInt(item['page']);
      final int? start = _asInt(item['start']);
      final int? end = _asInt(item['end']);
      if (page == null || start == null || end == null) return null;
      ranges.add(_StoredRange(page: page, start: start, end: end));
    }

    final List<String> pieces = <String>[];
    for (final _StoredRange range in ranges) {
      final String? text = await _safeLoad(range.page);
      if (text == null ||
          range.start < 0 ||
          range.end < range.start ||
          range.end > text.length) {
        return null;
      }
      pieces.add(text.substring(range.start, range.end));
    }

    final String joined = pieces.join('\n');
    if (joined != quote && pieces.join() != quote) return null;

    final List<Map<String, Object?>> geometry = <Map<String, Object?>>[];
    for (final _StoredRange range in ranges) {
      geometry.addAll(await _geometry(range.page, range.start, range.end));
    }

    final _StoredRange first = ranges.first;
    return AnchorResolution.resolved(
      location: _location(first.page, first.start, first.end),
      strategy: AnchorResolutionStrategy.storedLocator,
      confidence: 0.99,
      reason: 'Verified all stored multi-page fallback ranges.',
      sourceGeometry: geometry,
    );
  }

  Future<AnchorResolution> _resolved({
    required int page,
    required int start,
    required int end,
    required AnchorResolutionStrategy strategy,
    required double confidence,
  }) async {
    return AnchorResolution.resolved(
      location: _location(page, start, end),
      strategy: strategy,
      confidence: confidence,
      sourceGeometry: await _geometry(page, start, end),
    );
  }

  Future<List<Map<String, Object?>>> _geometry(
    int page,
    int start,
    int end,
  ) async {
    final PdfRangeGeometryLoader? loader = loadRangeGeometry;
    if (loader == null) return const <Map<String, Object?>>[];
    return loader(page, start, end);
  }

  Future<String?> _safeLoad(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > pageCount) return null;
    return loadPageText(pageNumber);
  }

  static bool _rangeMatches(
    String? text,
    int start,
    int end,
    String quote,
  ) {
    if (text == null || start < 0 || end < start || end > text.length) {
      return false;
    }
    return text.substring(start, end) == quote;
  }

  static int _contextScore(
    String text,
    int start,
    int end,
    String? prefix,
    String? suffix,
  ) {
    int score = 0;
    if (prefix != null && prefix.isNotEmpty) {
      final String before = text.substring(0, start);
      if (before.endsWith(prefix)) score += 1;
    }
    if (suffix != null && suffix.isNotEmpty) {
      final String after = text.substring(end);
      if (after.startsWith(suffix)) score += 1;
    }
    return score;
  }

  static DocumentLocation _location(int page, int start, int end) {
    return DocumentLocation(
      scheme: 'pdf',
      data: <String, Object?>{'page': page, 'start': start, 'end': end},
      label: 'Page $page',
    );
  }

  static int? _asInt(Object? value) => value is num ? value.toInt() : null;
}

final class _StoredRange {
  const _StoredRange({required this.page, required this.start, required this.end});

  final int page;
  final int start;
  final int end;
}

final class _QuoteCandidate {
  const _QuoteCandidate({
    required this.page,
    required this.start,
    required this.end,
    required this.contextScore,
  });

  final int page;
  final int start;
  final int end;
  final int contextScore;
}
