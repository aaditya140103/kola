import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/text/document_text_geometry.dart';

final class DocumentTextSelectionRange {
  DocumentTextSelectionRange({
    required this.location,
    required this.start,
    required this.end,
    required this.text,
    required List<DocumentRect> rects,
    this.prefixContext,
    this.suffixContext,
  }) : rects = List<DocumentRect>.unmodifiable(rects);

  final DocumentLocation location;
  final int start;
  final int end;
  final String text;
  final List<DocumentRect> rects;
  final String? prefixContext;
  final String? suffixContext;

  int? get pageNumber {
    final Object? raw = location.data['page'];
    return raw is num ? raw.toInt() : null;
  }
}

final class DocumentTextSelection {
  DocumentTextSelection({
    required this.documentId,
    required this.text,
    required List<DocumentTextSelectionRange> ranges,
  }) : ranges = List<DocumentTextSelectionRange>.unmodifiable(ranges);

  final String documentId;
  final String text;
  final List<DocumentTextSelectionRange> ranges;

  bool get isEmpty => text.trim().isEmpty || ranges.isEmpty;
}

final class FidelityTextHighlight {
  FidelityTextHighlight({
    required this.id,
    required List<Map<String, Object?>> sourceGeometry,
    this.colorToken,
  }) : sourceGeometry = List<Map<String, Object?>>.unmodifiable(
         sourceGeometry.map(Map<String, Object?>.unmodifiable),
       );

  final String id;
  final List<Map<String, Object?>> sourceGeometry;
  final String? colorToken;
}
