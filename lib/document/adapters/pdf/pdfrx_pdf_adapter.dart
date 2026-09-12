import 'package:kola/document/adapters/pdf/pdf_anchor_recovery_profile.dart';
import 'package:kola/document/adapters/pdf/pdf_anchor_resolver.dart';
import 'package:kola/document/adapters/pdf/pdf_exact_quote_index.dart';
import 'package:kola/document/adapters/pdf/pdf_page_text_cache.dart';
import 'package:kola/document/adapters/pdf/pdf_text_geometry_mapper.dart';
import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:kola/document/text/document_text_range_geometry.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

final class PdfrxPdfAdapter implements DocumentAdapter, BatchAnchorResolver {
  const PdfrxPdfAdapter(
    this._sourceResolver, {
    this.onAnchorRecoveryProfile,
  });

  static const String _graphVersion = 'pdf-text-v1';

  final DocumentSourceResolver _sourceResolver;
  final PdfAnchorRecoveryProfileObserver? onAnchorRecoveryProfile;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  FormatCapabilities get capabilities => const FormatCapabilities(
    fidelityView: true,
    textSelection: true,
    textSearch: true,
    textAnnotations: true,
    outline: true,
  );

  @override
  Future<DocumentMetadata> readMetadata(DocumentSource source) async {
    final String readablePath = await _sourceResolver.resolveReadablePath(source);
    final String fallbackPath = source.uri.scheme == 'file'
        ? source.uri.toFilePath()
        : readablePath;
    return DocumentMetadata(title: _titleFromPath(fallbackPath));
  }

  @override
  Future<DocumentHandle> open(KolaDocument document) async {
    final String path = await _sourceResolver.resolveReadablePath(document.source);
    final pdfrx.PdfDocument pdf = await pdfrx.PdfDocument.openFile(
      path,
      useProgressiveLoading: true,
    );
    return PdfrxPdfHandle(
      documentId: document.id,
      path: path,
      pdf: pdf,
      loadPageChunk: (int pageNumber) =>
          _loadPageChunkUncached(document.id, pdf, pageNumber),
    );
  }

  @override
  Future<FidelityDescriptor> buildFidelityView(DocumentHandle handle) async {
    _requireHandle(handle);
    return const FidelityDescriptor(kind: FidelitySurfaceKind.pdfPages);
  }

  @override
  Stream<DocumentTextChunk> extractTextGeometry(DocumentHandle handle) async* {
    final PdfrxPdfHandle pdfHandle = _requireHandle(handle);
    for (final pdfrx.PdfPage page in pdfHandle.pdf.pages) {
      try {
        yield await _loadPageChunk(pdfHandle, page.pageNumber);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
          PdfTextExtractionException(
            documentId: pdfHandle.documentId,
            pageNumber: page.pageNumber,
            cause: error,
          ),
          stackTrace,
        );
      }
    }
  }

  @override
  Stream<GraphChunk> buildDocumentGraph(
    DocumentHandle handle,
    GraphBuildOptions options,
  ) async* {
    final PdfrxPdfHandle pdfHandle = _requireHandle(handle);
    int pageIndex = 0;
    await for (final DocumentTextChunk chunk in extractTextGeometry(pdfHandle)) {
      pageIndex += 1;
      yield GraphChunk(
        documentId: pdfHandle.documentId,
        graphVersion: _graphVersion,
        flowQuality: FlowQuality.extracted,
        nodes: <KolaGraphNode>[
          KolaGraphNode(
            id: '${pdfHandle.documentId}:pdf-page:$pageIndex',
            kind: KolaNodeKind.sourceVisualBlock,
            text: chunk.text,
            sourceLocation: chunk.location,
            weight: chunk.text.trim().isEmpty ? 0.0 : 1.0,
            attributes: <String, Object?>{
              'page': pageIndex,
              'coordinateSpace': chunk.coordinateSpace.name,
              'pageWidth': chunk.extentWidth,
              'pageHeight': chunk.extentHeight,
              'rotationDegrees': chunk.rotationDegrees,
              'fragmentCount': chunk.fragments.length,
            },
          ),
        ],
        isFinal: pageIndex == pdfHandle.pageCount,
      );
    }
  }

  @override
  Stream<IndexChunk> extractIndexableContent(DocumentHandle handle) async* {
    final PdfrxPdfHandle pdfHandle = _requireHandle(handle);
    await for (final DocumentTextChunk chunk in extractTextGeometry(pdfHandle)) {
      if (chunk.text.trim().isEmpty) continue;
      final Object? page = chunk.location.data['page'];
      yield IndexChunk(
        documentId: pdfHandle.documentId,
        text: chunk.text,
        location: chunk.location,
        sectionLabel: page == null ? null : 'Page $page',
      );
    }
  }

  @override
  Future<AnchorResolution> resolveAnchor(
    DocumentHandle handle,
    AnnotationAnchor anchor,
  ) async {
    final PdfrxPdfHandle pdfHandle = _requireHandle(handle);
    if (anchor.documentId != pdfHandle.documentId) {
      return const AnchorResolution.unresolved(
        reason: 'Anchor belongs to a different document.',
      );
    }

    final PdfAnchorResolver resolver = PdfAnchorResolver(
      pageCount: pdfHandle.pageCount,
      loadPageText: (int pageNumber) async =>
          (await _loadPageChunk(pdfHandle, pageNumber)).text,
      loadRangeGeometry: (int pageNumber, int start, int end) async {
        return sourceGeometryForRange(
          await _loadPageChunk(pdfHandle, pageNumber),
          start: start,
          end: end,
        );
      },
      lookupQuoteCandidates: pdfHandle.quoteIndex.lookup,
      onProfile: onAnchorRecoveryProfile,
    );
    return resolver.resolve(anchor);
  }

  @override
  Future<List<AnchorResolution>> resolveAnchors(
    DocumentHandle handle,
    List<AnnotationAnchor> anchors,
  ) async {
    final PdfrxPdfHandle pdfHandle = _requireHandle(handle);
    final Set<String> quotes = <String>{};
    for (final AnnotationAnchor anchor in anchors) {
      final String? quote = anchor.exactQuote;
      if (anchor.documentId == pdfHandle.documentId &&
          quote != null &&
          quote.isNotEmpty) {
        quotes.add(quote);
      }
    }
    if (quotes.isNotEmpty) {
      try {
        // One handle-scoped multi-quote pass replaces one full-document scan
        // per distinct stale quote; per-anchor lookups below reuse the cache.
        await pdfHandle.quoteIndex.warmUp(quotes);
      } catch (_) {
        // A failed warm-up changes nothing: each resolution below performs
        // (or fails from) its own scan exactly like the single-anchor path.
      }
    }

    final List<AnchorResolution> resolutions = <AnchorResolution>[];
    for (final AnnotationAnchor anchor in anchors) {
      resolutions.add(await resolveAnchor(handle, anchor));
    }
    return resolutions;
  }

  Future<DocumentTextChunk> _loadPageChunk(
    PdfrxPdfHandle handle,
    int pageNumber,
  ) async {
    final DocumentTextChunk? chunk = await handle.textCache.get(pageNumber);
    if (chunk == null) {
      throw StateError('PDF page $pageNumber did not produce text geometry.');
    }
    return chunk;
  }

  Future<DocumentTextChunk> _loadPageChunkUncached(
    String documentId,
    pdfrx.PdfDocument pdf,
    int pageNumber,
  ) async {
    final pdfrx.PdfPage page = pdf.pages[pageNumber - 1];
    final pdfrx.PdfPageText pageText = await page.loadStructuredText();
    return PdfTextGeometryMapper.fromPdfrx(
      documentId: documentId,
      pageNumber: page.pageNumber,
      pageWidth: page.width,
      pageHeight: page.height,
      rotation: page.rotation,
      pageText: pageText,
    );
  }

  @override
  Future<ExportResult> export(ExportRequest request) {
    throw UnsupportedError(
      'PDF export is not integrated in the first fidelity milestone.',
    );
  }

  static PdfrxPdfHandle _requireHandle(DocumentHandle handle) {
    if (handle is! PdfrxPdfHandle) {
      throw ArgumentError.value(handle, 'handle', 'Expected PdfrxPdfHandle.');
    }
    return handle;
  }

  static String _titleFromPath(String path) {
    final String name = path.split(RegExp(r'[\\/]')).last;
    final int dot = name.lastIndexOf('.');
    final String title = dot > 0 ? name.substring(0, dot) : name;
    return title.trim().isEmpty ? 'Untitled PDF' : title.trim();
  }
}

final class PdfrxPdfHandle implements DocumentHandle {
  PdfrxPdfHandle({
    required this.documentId,
    required this.path,
    required this.pdf,
    required PdfPageTextChunkLoader loadPageChunk,
  }) {
    textCache = PdfPageTextCache(loadPageChunk);
    quoteIndex = PdfExactQuoteIndex(
      pageCount: pdf.pages.length,
      loadPageText: (int pageNumber) async =>
          (await textCache.get(pageNumber))?.text,
    );
  }

  @override
  final String documentId;

  final String path;
  final pdfrx.PdfDocument pdf;
  late final PdfPageTextCache textCache;
  late final PdfExactQuoteIndex quoteIndex;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  int get pageCount => pdf.pages.length;

  @override
  Future<void> close() async {
    quoteIndex.clear();
    textCache.clear();
    await pdf.dispose();
  }
}

final class PdfTextExtractionException implements Exception {
  const PdfTextExtractionException({
    required this.documentId,
    required this.pageNumber,
    required this.cause,
  });

  final String documentId;
  final int pageNumber;
  final Object cause;

  @override
  String toString() =>
      'Failed to extract PDF text for $documentId on page $pageNumber: $cause';
}
