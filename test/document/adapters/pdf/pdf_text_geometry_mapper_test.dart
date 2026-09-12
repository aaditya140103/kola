import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdf_text_geometry_mapper.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

void main() {
  test('maps pdfrx page text into Kola source geometry', () {
    const String fullText = 'Hello';
    final List<pdfrx.PdfRect> characterRects = <pdfrx.PdfRect>[
      const pdfrx.PdfRect(10, 30, 15, 20),
      const pdfrx.PdfRect(15, 30, 20, 20),
      const pdfrx.PdfRect(20, 30, 25, 20),
      const pdfrx.PdfRect(25, 30, 30, 20),
      const pdfrx.PdfRect(30, 30, 35, 20),
    ];
    final List<pdfrx.PdfPageTextFragment> fragments =
        <pdfrx.PdfPageTextFragment>[];
    final pdfrx.PdfPageText pageText = pdfrx.PdfPageText(
      pageNumber: 3,
      fullText: fullText,
      charRects: characterRects,
      fragments: fragments,
    );
    fragments.add(
      pdfrx.PdfPageTextFragment(
        pageText: pageText,
        index: 0,
        length: fullText.length,
        bounds: const pdfrx.PdfRect(10, 30, 35, 20),
        charRects: characterRects,
        direction: pdfrx.PdfTextDirection.ltr,
      ),
    );

    final DocumentTextChunk chunk = PdfTextGeometryMapper.fromPdfrx(
      documentId: 'sha256:geometry-test',
      pageNumber: 3,
      pageWidth: 612,
      pageHeight: 792,
      rotation: pdfrx.PdfPageRotation.clockwise90,
      pageText: pageText,
    );

    expect(chunk.documentId, 'sha256:geometry-test');
    expect(chunk.location.scheme, 'pdf');
    expect(chunk.location.data['page'], 3);
    expect(chunk.location.data['start'], 0);
    expect(chunk.location.data['end'], fullText.length);
    expect(chunk.text, fullText);
    expect(chunk.coordinateSpace, DocumentCoordinateSpace.pdfPagePoints);
    expect(chunk.extentWidth, 612);
    expect(chunk.extentHeight, 792);
    expect(chunk.rotationDegrees, 90);
    expect(chunk.characterBounds, hasLength(fullText.length));
    expect(chunk.characterBounds.first.left, 10);
    expect(chunk.characterBounds.first.top, 30);
    expect(chunk.characterBounds.first.right, 15);
    expect(chunk.characterBounds.first.bottom, 20);
    expect(chunk.fragments, hasLength(1));
    expect(chunk.fragments.single.start, 0);
    expect(chunk.fragments.single.end, fullText.length);
    expect(chunk.fragments.single.direction, DocumentTextDirection.ltr);
    expect(chunk.textFor(chunk.fragments.single), fullText);
  });
}
