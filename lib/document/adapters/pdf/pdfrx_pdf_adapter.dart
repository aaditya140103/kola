import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

final class PdfrxPdfAdapter implements DocumentAdapter {
  const PdfrxPdfAdapter(this._sourceResolver);

  final DocumentSourceResolver _sourceResolver;

  @override
  DocumentFormat get format => DocumentFormat.pdf;

  @override
  FormatCapabilities get capabilities => const FormatCapabilities(
    fidelityView: true,
    outline: true,
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
  Stream<GraphChunk> buildDocumentGraph(
    DocumentHandle handle,
    GraphBuildOptions options,
  ) {
    _requireHandle(handle);
    return const Stream<GraphChunk>.empty();
  }

  @override
  Stream<IndexChunk> extractIndexableContent(DocumentHandle handle) {
    _requireHandle(handle);
    return const Stream<IndexChunk>.empty();
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
