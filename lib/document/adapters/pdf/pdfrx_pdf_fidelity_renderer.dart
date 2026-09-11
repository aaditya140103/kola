import 'package:flutter/material.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:pdfrx/pdfrx.dart';

final class PdfrxPdfFidelityRenderer implements DocumentFidelityRenderer {
  const PdfrxPdfFidelityRenderer(this._sourceResolver);

  final DocumentSourceResolver _sourceResolver;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  Widget build(BuildContext context, KolaDocument document) {
    return _PdfrxPdfFidelityView(
      document: document,
      sourceResolver: _sourceResolver,
    );
  }
}

class _PdfrxPdfFidelityView extends StatefulWidget {
  const _PdfrxPdfFidelityView({
    required this.document,
    required this.sourceResolver,
  });

  final KolaDocument document;
  final DocumentSourceResolver sourceResolver;

  @override
  State<_PdfrxPdfFidelityView> createState() => _PdfrxPdfFidelityViewState();
}

class _PdfrxPdfFidelityViewState extends State<_PdfrxPdfFidelityView> {
  final PdfViewerController _controller = PdfViewerController();
  late Future<String> _pathFuture;
  int? _pageNumber;
  int? _pageCount;

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
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: PdfViewer.file(
                snapshot.data!,
                controller: _controller,
                useProgressiveLoading: true,
                params: PdfViewerParams(
                  margin: KolaSpacing.md,
                  enableKeyboardNavigation: true,
                  textSelectionParams: const PdfTextSelectionParams(enabled: false),
                  onViewerReady: (PdfDocument document, PdfViewerController controller) {
                    if (!mounted) return;
                    setState(() {
                      _pageCount = controller.pageCount;
                      _pageNumber = controller.pageNumber ?? 1;
                    });
                  },
                  onPageChanged: (int? pageNumber) {
                    if (!mounted || pageNumber == _pageNumber) return;
                    setState(() => _pageNumber = pageNumber);
                  },
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

  Future<void> _goPrevious() async {
    if (!_controller.isReady) return;
    final int current = _controller.pageNumber ?? 1;
    if (current <= 1) return;
    await _controller.goToPage(pageNumber: current - 1, anchor: PdfPageAnchor.top);
  }

  Future<void> _goNext() async {
    if (!_controller.isReady) return;
    final int current = _controller.pageNumber ?? 1;
    if (current >= _controller.pageCount) return;
    await _controller.goToPage(pageNumber: current + 1, anchor: PdfPageAnchor.top);
  }

  Future<void> _zoomOut() async {
    if (_controller.isReady) await _controller.zoomDown();
  }

  Future<void> _zoomIn() async {
    if (_controller.isReady) await _controller.zoomUp();
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
