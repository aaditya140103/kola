import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/text/document_text_geometry.dart';

enum FidelitySurfaceKind {
  pdfPages,
  wordLayout,
  slides,
  sheets,
  comicPages,
  fixedLayout,
}

final class FormatCapabilities {
  const FormatCapabilities({
    this.fidelityView = false,
    this.flowMode = false,
    this.textSelection = false,
    this.textSearch = false,
    this.textAnnotations = false,
    this.areaAnnotations = false,
    this.inkAnnotations = false,
    this.spreadsheetRanges = false,
    this.slideRegions = false,
    this.outline = false,
    this.embeddedMedia = false,
    this.localOcr = false,
    this.exportEmbeddedAnnotations = false,
  });

  final bool fidelityView;
  final bool flowMode;
  final bool textSelection;
  final bool textSearch;
  final bool textAnnotations;
  final bool areaAnnotations;
  final bool inkAnnotations;
  final bool spreadsheetRanges;
  final bool slideRegions;
  final bool outline;
  final bool embeddedMedia;
  final bool localOcr;
  final bool exportEmbeddedAnnotations;
}

abstract interface class DocumentHandle {
  String get documentId;
  DocumentFormat get format;
  Future<void> close();
}

final class FidelityDescriptor {
  const FidelityDescriptor({required this.kind});

  final FidelitySurfaceKind kind;
}

final class GraphBuildOptions {
  const GraphBuildOptions({
    this.preferOcr = false,
    this.preserveComplexVisuals = true,
  });

  final bool preferOcr;
  final bool preserveComplexVisuals;
}

final class AnnotationAnchor {
  AnnotationAnchor({
    required this.documentId,
    this.sourceLocator,
    this.graphNodeIds = const <String>[],
    this.exactQuote,
    this.prefixContext,
    this.suffixContext,
    this.logicalStart,
    this.logicalEnd,
    List<Map<String, Object?>> sourceGeometry = const <Map<String, Object?>>[],
    Map<String, Object?> formatSpecificFallback = const <String, Object?>{},
  }) : sourceGeometry = List<Map<String, Object?>>.unmodifiable(
         sourceGeometry.map(Map<String, Object?>.unmodifiable),
       ),
       formatSpecificFallback = Map<String, Object?>.unmodifiable(
         formatSpecificFallback,
       );

  final String documentId;
  final DocumentLocation? sourceLocator;
  final List<String> graphNodeIds;
  final String? exactQuote;
  final String? prefixContext;
  final String? suffixContext;
  final int? logicalStart;
  final int? logicalEnd;
  final List<Map<String, Object?>> sourceGeometry;
  final Map<String, Object?> formatSpecificFallback;
}

final class ExportRequest {
  const ExportRequest({
    required this.documentId,
    required this.kind,
    required this.destination,
  });

  final String documentId;
  final String kind;
  final Uri destination;
}

final class ExportResult {
  const ExportResult({required this.output, this.warning});

  final Uri output;
  final String? warning;
}

abstract interface class DocumentAdapter {
  DocumentFormat get format;
  FormatCapabilities get capabilities;

  Future<DocumentMetadata> readMetadata(DocumentSource source);
  Future<DocumentHandle> open(KolaDocument document);
  Future<FidelityDescriptor?> buildFidelityView(DocumentHandle handle);

  Stream<DocumentTextChunk> extractTextGeometry(DocumentHandle handle);

  Stream<GraphChunk> buildDocumentGraph(
    DocumentHandle handle,
    GraphBuildOptions options,
  );

  Stream<IndexChunk> extractIndexableContent(DocumentHandle handle);

  Future<AnchorResolution> resolveAnchor(
    DocumentHandle handle,
    AnnotationAnchor anchor,
  );

  Future<ExportResult> export(ExportRequest request);
}
