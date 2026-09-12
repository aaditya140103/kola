import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/adapters/pdf/pdf_fidelity_position.dart';
import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:kola/document/text/document_text_selection.dart';
import 'package:pdfrx/pdfrx.dart';

final class PdfrxPdfFidelityRenderer implements DocumentFidelityRenderer {
  const PdfrxPdfFidelityRenderer(this._sourceResolver);

  final DocumentSourceResolver _sourceResolver;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  Widget build(
    BuildContext context,
    KolaDocument document, {
    FidelityViewState? initialState,
    FidelityNavigationRequest? navigationRequest,
    ValueChanged<FidelityViewState>? onStateChanged,
    ValueChanged<DocumentTextSelection>? onTextSelection,
    List<FidelityTextHighlight> highlights = const <FidelityTextHighlight>[],
  }) {
    return _PdfrxPdfFidelityView(
      document: document,
      sourceResolver: _sourceResolver,
      initialState: initialState,
      navigationRequest: navigationRequest,
      onStateChanged: onStateChanged,
      onTextSelection: onTextSelection,
      highlights: highlights,
    );
  }
}

class _PdfrxPdfFidelityView extends StatefulWidget {
  const _PdfrxPdfFidelityView({
    required this.document,
    required this.sourceResolver,
    required this.highlights,
    this.initialState,
    this.navigationRequest,
    this.onStateChanged,
    this.onTextSelection,
  });

  final KolaDocument document;
  final DocumentSourceResolver sourceResolver;
  final FidelityViewState? initialState;
  final FidelityNavigationRequest? navigationRequest;
  final ValueChanged<FidelityViewState>? onStateChanged;
  final ValueChanged<DocumentTextSelection>? onTextSelection;
  final List<FidelityTextHighlight> highlights;

  @override
  State<_PdfrxPdfFidelityView> createState() => _PdfrxPdfFidelityViewState();
}

class _PdfrxPdfFidelityViewState extends State<_PdfrxPdfFidelityView> {
  static const int _contextCharacters = 48;

  final PdfViewerController _controller = PdfViewerController();
  late Future<String> _pathFuture;
  int? _pageNumber;
  int? _pageCount;
  int? _lastNavigationSequence;

  @override
  void initState() {
    super.initState();
    _pathFuture = widget.sourceResolver.resolveReadablePath(widget.document.source);
  }

  @override
  void didUpdateWidget(covariant _PdfrxPdfFidelityView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id ||
        oldWidget.document.source.uri != widget.document.source.uri ||
        oldWidget.document.source.managedPath != widget.document.source.managedPath) {
      _pathFuture = widget.sourceResolver.resolveReadablePath(widget.document.source);
      _pageNumber = null;
      _pageCount = null;
      _lastNavigationSequence = null;
    }

    if (widget.navigationRequest?.sequence !=
        oldWidget.navigationRequest?.sequence) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyNavigationRequest(widget.navigationRequest);
      });
    }

    if (!identical(widget.highlights, oldWidget.highlights)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.isReady) {
          _controller.invalidate();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _pathFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _PdfLoadError(error: snapshot.error);
        }

        final int initialPage = PdfFidelityPosition.initialPageNumber(
          widget.initialState,
        );
        final double? initialZoom = PdfFidelityPosition.initialZoom(
          widget.initialState,
        );
        final bool selectionEnabled = widget.onTextSelection != null;

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: PdfViewer.file(
                snapshot.data!,
                controller: _controller,
                initialPageNumber: initialPage,
                useProgressiveLoading: true,
                params: PdfViewerParams(
                  margin: KolaSpacing.md,
                  enableKeyboardNavigation: true,
                  sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
                    calculateInitialZoom: initialZoom == null
                        ? null
                        : (
                            PdfDocument document,
                            PdfViewerController controller,
                            double fitZoom,
                            double coverZoom,
                          ) => initialZoom,
                  ),
                  textSelectionParams: PdfTextSelectionParams(
                    enabled: selectionEnabled,
                    showContextMenuAutomatically: selectionEnabled,
                  ),
                  customizeContextMenuItems: selectionEnabled
                      ? _customizeContextMenuItems
                      : null,
                  pagePaintCallbacks: <PdfViewerPagePaintCallback>[
                    _paintHighlights,
                  ],
                  onViewerReady: (
                    PdfDocument document,
                    PdfViewerController controller,
                  ) {
                    if (!mounted) return;
                    setState(() {
                      _pageCount = controller.pageCount;
                      _pageNumber = controller.pageNumber ?? initialPage;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _applyNavigationRequest(widget.navigationRequest);
                    });
                  },
                  onPageChanged: (int? pageNumber) {
                    if (!mounted || pageNumber == null) return;
                    if (pageNumber != _pageNumber) {
                      setState(() => _pageNumber = pageNumber);
                    }
                    _emitPosition();
                  },
                  onInteractionEnd: (ScaleEndDetails details) => _emitPosition(),
                ),
              ),
            ),
            Positioned(
              left: KolaSpacing.md,
              right: KolaSpacing.md,
              bottom: KolaSpacing.md,
              child: _PdfNavigationBar(
                pageNumber: _pageNumber,
                pageCount: _pageCount,
                onPrevious: _goPrevious,
                onNext: _goNext,
                onZoomOut: _zoomOut,
                onZoomIn: _zoomIn,
              ),
            ),
          ],
        );
      },
    );
  }

  void _customizeContextMenuItems(
    PdfViewerContextMenuBuilderParams params,
    List<ContextMenuButtonItem> items,
  ) {
    final PdfTextSelectionDelegate delegate = params.textSelectionDelegate;
    if (!delegate.hasSelectedText || !delegate.isCopyAllowed) return;

    items.insert(
      0,
      ContextMenuButtonItem(
        label: 'Highlight',
        onPressed: () {
          params.dismissContextMenu();
          unawaited(_emitSelection(delegate));
        },
      ),
    );
  }

  Future<void> _emitSelection(PdfTextSelectionDelegate delegate) async {
    final ValueChanged<DocumentTextSelection>? callback = widget.onTextSelection;
    if (callback == null || !delegate.hasSelectedText || !delegate.isCopyAllowed) {
      return;
    }

    final List<PdfPageTextRange> rawRanges = await delegate.getSelectedTextRanges();
    if (rawRanges.isEmpty) return;

    final List<PdfPageTextRange> ranges = List<PdfPageTextRange>.of(rawRanges)
      ..sort((PdfPageTextRange a, PdfPageTextRange b) {
        final int pageComparison = a.pageNumber.compareTo(b.pageNumber);
        return pageComparison == 0 ? a.start.compareTo(b.start) : pageComparison;
      });

    String selectedText = await delegate.getSelectedText();
    if (selectedText.trim().isEmpty) {
      selectedText = ranges.map((PdfPageTextRange range) => range.text).join('\n');
    }
    if (selectedText.trim().isEmpty) return;

    final List<DocumentTextSelectionRange> mapped = ranges
        .map(_mapSelectionRange)
        .toList(growable: false);
    callback(
      DocumentTextSelection(
        documentId: widget.document.id,
        text: selectedText,
        ranges: mapped,
      ),
    );
    await delegate.clearTextSelection();
  }

  DocumentTextSelectionRange _mapSelectionRange(PdfPageTextRange range) {
    final String fullText = range.pageText.fullText;
    final int safeStart = range.start.clamp(0, fullText.length);
    final int safeEnd = range.end.clamp(safeStart, fullText.length);
    final int prefixStart = math.max(0, safeStart - _contextCharacters);
    final int suffixEnd = math.min(fullText.length, safeEnd + _contextCharacters);
    final List<DocumentRect> rects = range
        .enumerateFragmentBoundingRects()
        .map(
          (PdfTextFragmentBoundingRect fragment) => DocumentRect(
            left: fragment.bounds.left,
            top: fragment.bounds.top,
            right: fragment.bounds.right,
            bottom: fragment.bounds.bottom,
          ),
        )
        .where((DocumentRect rect) => rect.width > 0 && rect.height > 0)
        .toList(growable: false);

    return DocumentTextSelectionRange(
      location: DocumentLocation(
        scheme: 'pdf',
        data: <String, Object?>{
          'page': range.pageNumber,
          'start': safeStart,
          'end': safeEnd,
        },
        label: 'Page ${range.pageNumber}',
      ),
      start: safeStart,
      end: safeEnd,
      text: fullText.substring(safeStart, safeEnd),
      rects: rects,
      prefixContext: fullText.substring(prefixStart, safeStart),
      suffixContext: fullText.substring(safeEnd, suffixEnd),
    );
  }

  void _paintHighlights(Canvas canvas, Rect pageRect, PdfPage page) {
    if (widget.highlights.isEmpty) return;

    for (final FidelityTextHighlight highlight in widget.highlights) {
      final Paint paint = Paint()..color = _highlightColor(highlight.colorToken);
      for (final Map<String, Object?> geometry in highlight.sourceGeometry) {
        if (geometry['scheme'] != 'pdf') continue;
        final Object? rawPage = geometry['page'];
        if (rawPage is! num || rawPage.toInt() != page.pageNumber) continue;

        final double? left = _asDouble(geometry['left']);
        final double? top = _asDouble(geometry['top']);
        final double? right = _asDouble(geometry['right']);
        final double? bottom = _asDouble(geometry['bottom']);
        if (left == null || top == null || right == null || bottom == null) {
          continue;
        }

        final PdfRect sourceRect = PdfRect(left, top, right, bottom);
        final Rect paintRect = sourceRect.toRectInDocument(
          page: page,
          pageRect: pageRect,
        );
        canvas.drawRect(paintRect, paint);
      }
    }
  }

  static double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

  static Color _highlightColor(String? token) {
    return switch (token) {
      'highlight.blue' => Colors.lightBlueAccent.withValues(alpha: 0.30),
      'highlight.green' => Colors.lightGreenAccent.withValues(alpha: 0.30),
      'highlight.pink' => Colors.pinkAccent.withValues(alpha: 0.24),
      'highlight.purple' => Colors.purpleAccent.withValues(alpha: 0.24),
      'highlight.orange' => Colors.orangeAccent.withValues(alpha: 0.30),
      _ => Colors.yellowAccent.withValues(alpha: 0.30),
    };
  }

  Future<void> _applyNavigationRequest(
    FidelityNavigationRequest? request,
  ) async {
    if (!mounted || request == null || !_controller.isReady) return;
    if (request.sequence == _lastNavigationSequence) return;
    if (request.location.scheme != 'pdf') return;

    final Object? rawPage = request.location.data['page'];
    if (rawPage is! num) return;
    final int page = rawPage.toInt().clamp(1, _controller.pageCount).toInt();
    _lastNavigationSequence = request.sequence;
    await _controller.goToPage(pageNumber: page, anchor: PdfPageAnchor.top);
    if (!mounted) return;
    if (_pageNumber != page) setState(() => _pageNumber = page);
    _emitPosition();
  }

  void _emitPosition() {
    if (!_controller.isReady) return;
    final int? pageNumber = _controller.pageNumber;
    final int pageCount = _controller.pageCount;
    if (pageNumber == null || pageCount < 1) return;

    widget.onStateChanged?.call(
      PdfFidelityPosition.fromViewer(
        pageNumber: pageNumber,
        pageCount: pageCount,
        zoom: _controller.currentZoom,
      ),
    );
  }

  Future<void> _goPrevious() async {
    if (!_controller.isReady) return;
    final int current = _controller.pageNumber ?? 1;
    if (current <= 1) return;
    await _controller.goToPage(pageNumber: current - 1, anchor: PdfPageAnchor.top);
    _emitPosition();
  }

  Future<void> _goNext() async {
    if (!_controller.isReady) return;
    final int current = _controller.pageNumber ?? 1;
    if (current >= _controller.pageCount) return;
    await _controller.goToPage(pageNumber: current + 1, anchor: PdfPageAnchor.top);
    _emitPosition();
  }

  Future<void> _zoomOut() async {
    if (!_controller.isReady) return;
    await _controller.zoomDown();
    _emitPosition();
  }

  Future<void> _zoomIn() async {
    if (!_controller.isReady) return;
    await _controller.zoomUp();
    _emitPosition();
  }
}

class _PdfNavigationBar extends StatelessWidget {
  const _PdfNavigationBar({
    required this.pageNumber,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final int? pageNumber;
  final int? pageCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String pageLabel = pageNumber == null || pageCount == null
        ? 'Loading pages…'
        : 'Page $pageNumber of $pageCount';

    return Center(
      child: Material(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: KolaRadius.pill,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KolaSpacing.xs,
            vertical: KolaSpacing.xxs,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: onPrevious,
                tooltip: 'Previous page',
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 116),
                child: Text(pageLabel, textAlign: TextAlign.center),
              ),
              IconButton(
                onPressed: onNext,
                tooltip: 'Next page',
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: KolaSpacing.xs),
              IconButton(
                onPressed: onZoomOut,
                tooltip: 'Zoom out',
                icon: const Icon(Icons.remove_rounded),
              ),
              IconButton(
                onPressed: onZoomIn,
                tooltip: 'Zoom in',
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfLoadError extends StatelessWidget {
  const _PdfLoadError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(KolaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: KolaSpacing.md),
              Text(
                'Kola cannot open this PDF source.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolaSpacing.sm),
              Text(
                error?.toString() ?? 'The local source is unavailable.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
