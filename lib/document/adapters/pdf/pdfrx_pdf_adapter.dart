import 'package:kola/document/adapters/pdf/pdf_text_geometry_mapper.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

final class PdfrxPdfAdapter implements DocumentAdapter {
  const PdfrxPdfAdapter(this._sourceResolver);

  static const String _graphVersion = 'pdf-text-v1';

  final DocumentSourceResolver _sourceResolver;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  FormatCapabilities get capabilities => const FormatCapabilities(
    fidelityView: true,
    textSelection: true,
    textSearch: true,
    textAnnotations: true,
  );

  @override
  Future<DocumentMetadata> readMetadata(DocumentSource source) async {
    final String path = await _sourceResolver.resolveReadablePath(source);
    return DocumentMetadata(title: _titleFromPath(path));
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
        final pdfrx.PdfPageText pageText = await page.loadStructuredText();
        yield PdfTextGeometryMapper.fromPdfrx(
          documentId: pdfHandle.documentId,
          pageNumber: page.pageNumber,
          pageWidth: page.width,
          pageHeight: page.height,
          rotation: page.rotation,
          pageText: pageText,
        );
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
  Future<DocumentLocation?> resolveAnchor(
    DocumentHandle handle,
    AnnotationAnchor anchor,
  ) async {
    _requireHandle(handle);
    final DocumentLocation? locator = anchor.sourceLocator;
    if (anchor.documentId != handle.documentId || locator?.scheme != 'pdf') {
      return null;
    }
    return locator;
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
  const PdfrxPdfHandle({
    required this.documentId,
    required this.path,
    required this.pdf,
  });

  @override
  final String documentId;

  final String path;
  final pdfrx.PdfDocument pdf;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  int get pageCount => pdf.pages.length;

  @override
  Future<void> close() => pdf.dispose();
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
