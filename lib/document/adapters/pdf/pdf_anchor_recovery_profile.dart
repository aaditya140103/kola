import 'package:kola/document/anchors/anchor_resolution.dart';

/// Local, ephemeral diagnostics for one PDF anchor-resolution attempt.
///
/// Profiles are intended for tests, development diagnostics, and measured
/// optimization. They are not persisted or transmitted.
final class PdfAnchorRecoveryProfile {
  const PdfAnchorRecoveryProfile({
    required this.resolved,
    required this.strategy,
    required this.pageLoadRequests,
    required this.uniquePagesRequested,
    required this.quoteSearchPagesScanned,
    required this.quoteCandidatesFound,
    required this.elapsed,
  });

  final bool resolved;
  final AnchorResolutionStrategy? strategy;
  final int pageLoadRequests;
  final int uniquePagesRequested;
  final int quoteSearchPagesScanned;
  final int quoteCandidatesFound;
  final Duration elapsed;
}

typedef PdfAnchorRecoveryProfileObserver = void Function(
  PdfAnchorRecoveryProfile profile,
);

final class PdfAnchorRecoveryProfiler {
  PdfAnchorRecoveryProfiler(this._observer) : _stopwatch = Stopwatch()..start();

  final PdfAnchorRecoveryProfileObserver? _observer;
  final Stopwatch _stopwatch;
  final Set<int> _uniquePagesRequested = <int>{};

  int _pageLoadRequests = 0;
  int _quoteSearchPagesScanned = 0;
  int _quoteCandidatesFound = 0;

  void recordPageRequest(int pageNumber) {
    _pageLoadRequests += 1;
    _uniquePagesRequested.add(pageNumber);
  }

  void recordQuoteSearchPage() => _quoteSearchPagesScanned += 1;

  void recordQuoteCandidate() => _quoteCandidatesFound += 1;

  void complete(AnchorResolution resolution) {
    _stopwatch.stop();
    _observer?.call(
      PdfAnchorRecoveryProfile(
        resolved: resolution.resolved,
        strategy: resolution.strategy,
        pageLoadRequests: _pageLoadRequests,
        uniquePagesRequested: _uniquePagesRequested.length,
        quoteSearchPagesScanned: _quoteSearchPagesScanned,
        quoteCandidatesFound: _quoteCandidatesFound,
        elapsed: _stopwatch.elapsed,
      ),
    );
  }
}
