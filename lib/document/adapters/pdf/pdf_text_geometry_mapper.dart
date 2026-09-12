import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

abstract final class PdfTextGeometryMapper {
  static DocumentTextChunk fromPdfrx({
    required String documentId,
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required pdfrx.PdfPageRotation rotation,
    required pdfrx.PdfPageText pageText,
  }) {
    return DocumentTextChunk(
      documentId: documentId,
      location: DocumentLocation(
        scheme: 'pdf',
        data: <String, Object?>{
          'page': pageNumber,
          'start': 0,
          'end': pageText.fullText.length,
        },
        label: 'Page $pageNumber',
      ),
      text: pageText.fullText,
      coordinateSpace: DocumentCoordinateSpace.pdfPagePoints,
      extentWidth: pageWidth,
      extentHeight: pageHeight,
      rotationDegrees: _rotationDegrees(rotation),
      characterBounds: pageText.charRects.map(_mapRect).toList(growable: false),
      fragments: pageText.fragments
          .map(
            (pdfrx.PdfPageTextFragment fragment) => DocumentTextFragment(
              start: fragment.index,
              end: fragment.end,
              bounds: _mapRect(fragment.bounds),
              direction: _mapDirection(fragment.direction),
            ),
          )
          .toList(growable: false),
    );
  }

  static DocumentRect _mapRect(pdfrx.PdfRect rect) {
    return DocumentRect(
      left: rect.left,
      top: rect.top,
      right: rect.right,
      bottom: rect.bottom,
    );
  }

  static DocumentTextDirection _mapDirection(pdfrx.PdfTextDirection direction) {
    return switch (direction) {
      pdfrx.PdfTextDirection.ltr => DocumentTextDirection.ltr,
      pdfrx.PdfTextDirection.rtl => DocumentTextDirection.rtl,
      pdfrx.PdfTextDirection.vrtl => DocumentTextDirection.verticalRtl,
      pdfrx.PdfTextDirection.unknown => DocumentTextDirection.unknown,
    };
  }

  static int _rotationDegrees(pdfrx.PdfPageRotation rotation) {
    return switch (rotation) {
      pdfrx.PdfPageRotation.none => 0,
      pdfrx.PdfPageRotation.clockwise90 => 90,
      pdfrx.PdfPageRotation.clockwise180 => 180,
      pdfrx.PdfPageRotation.clockwise270 => 270,
    };
  }
}
