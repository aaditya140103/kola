import 'package:kola/document/text/document_text_geometry.dart';

List<Map<String, Object?>> sourceGeometryForRange(
  DocumentTextChunk chunk, {
  required int start,
  required int end,
}) {
  final int safeStart = start.clamp(0, chunk.text.length);
  final int safeEnd = end.clamp(safeStart, chunk.text.length);
  if (safeStart == safeEnd || chunk.characterBounds.isEmpty) {
    return const <Map<String, Object?>>[];
  }

  final int boundsEnd = safeEnd.clamp(0, chunk.characterBounds.length);
  final int boundsStart = safeStart.clamp(0, boundsEnd);
  if (boundsStart == boundsEnd) return const <Map<String, Object?>>[];

  final List<DocumentRect> merged = <DocumentRect>[];
  for (final DocumentRect rect in chunk.characterBounds.sublist(
    boundsStart,
    boundsEnd,
  )) {
    if (rect.width <= 0 || rect.height <= 0) continue;
    if (merged.isEmpty || !_sameLineAndAdjacent(merged.last, rect)) {
      merged.add(rect);
      continue;
    }
    final DocumentRect previous = merged.removeLast();
    merged.add(
      DocumentRect(
        left: previous.left < rect.left ? previous.left : rect.left,
        top: previous.top > rect.top ? previous.top : rect.top,
        right: previous.right > rect.right ? previous.right : rect.right,
        bottom: previous.bottom < rect.bottom ? previous.bottom : rect.bottom,
      ),
    );
  }

  final Object? rawPage = chunk.location.data['page'];
  final int? page = rawPage is num ? rawPage.toInt() : null;
  return merged
      .map(
        (DocumentRect rect) => <String, Object?>{
          'scheme': chunk.location.scheme,
          'coordinateSpace': chunk.coordinateSpace.name,
          'page': page,
          'start': safeStart,
          'end': safeEnd,
          'left': rect.left,
          'top': rect.top,
          'right': rect.right,
          'bottom': rect.bottom,
        },
      )
      .toList(growable: false);
}

bool _sameLineAndAdjacent(DocumentRect a, DocumentRect b) {
  const double lineTolerance = 1.5;
  const double gapTolerance = 3.0;
  final bool sameLine =
      (a.top - b.top).abs() <= lineTolerance &&
      (a.bottom - b.bottom).abs() <= lineTolerance;
  final double gap = b.left - a.right;
  return sameLine && gap >= -gapTolerance && gap <= gapTolerance;
}
