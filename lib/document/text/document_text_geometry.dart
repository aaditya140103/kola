import 'package:kola/document/model/document_models.dart';

enum DocumentCoordinateSpace { pdfPagePoints }

enum DocumentTextDirection { ltr, rtl, verticalRtl, unknown }

final class DocumentRect {
  const DocumentRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => top - bottom;
}

final class DocumentTextFragment {
  const DocumentTextFragment({
    required this.start,
    required this.end,
    required this.bounds,
    required this.direction,
  });

  final int start;
  final int end;
  final DocumentRect bounds;
  final DocumentTextDirection direction;
}

final class DocumentTextChunk {
  DocumentTextChunk({
    required this.documentId,
    required this.location,
    required this.text,
    required this.coordinateSpace,
    required this.extentWidth,
    required this.extentHeight,
    required this.rotationDegrees,
    required List<DocumentRect> characterBounds,
    required List<DocumentTextFragment> fragments,
  }) : characterBounds = List<DocumentRect>.unmodifiable(characterBounds),
       fragments = List<DocumentTextFragment>.unmodifiable(fragments);

  final String documentId;
  final DocumentLocation location;
  final String text;
  final DocumentCoordinateSpace coordinateSpace;
  final double extentWidth;
  final double extentHeight;
  final int rotationDegrees;
  final List<DocumentRect> characterBounds;
  final List<DocumentTextFragment> fragments;

  String textFor(DocumentTextFragment fragment) {
    final int safeStart = fragment.start.clamp(0, text.length);
    final int safeEnd = fragment.end.clamp(safeStart, text.length);
    return text.substring(safeStart, safeEnd);
  }
}
