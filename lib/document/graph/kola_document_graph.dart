import 'package:kola/document/model/document_models.dart';

enum KolaNodeKind {
  section,
  heading,
  paragraph,
  list,
  listItem,
  quote,
  image,
  figure,
  caption,
  table,
  tableRow,
  tableCell,
  code,
  footnote,
  slide,
  speakerNotes,
  sheet,
  cellRange,
  formulaDisplay,
  sourceVisualBlock,
}

enum FlowQuality { native, reconstructed, extracted, ocr }

final class KolaGraphNode {
  KolaGraphNode({
    required this.id,
    required this.kind,
    this.parentId,
    this.text,
    this.sourceLocation,
    this.weight = 1,
    Map<String, Object?> attributes = const <String, Object?>{},
  }) : attributes = Map<String, Object?>.unmodifiable(attributes);

  final String id;
  final KolaNodeKind kind;
  final String? parentId;
  final String? text;
  final DocumentLocation? sourceLocation;
  final double weight;
  final Map<String, Object?> attributes;
}

final class GraphChunk {
  const GraphChunk({
    required this.documentId,
    required this.graphVersion,
    required this.flowQuality,
    required this.nodes,
    this.isFinal = false,
  });

  final String documentId;
  final String graphVersion;
  final FlowQuality flowQuality;
  final List<KolaGraphNode> nodes;
  final bool isFinal;
}

final class IndexChunk {
  const IndexChunk({
    required this.documentId,
    required this.text,
    required this.location,
    this.sectionLabel,
  });

  final String documentId;
  final String text;
  final DocumentLocation location;
  final String? sectionLabel;
}
