import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:kola/document/text/document_text_range_geometry.dart';

void main() {
  test('rebuilds and merges current-source character rectangles', () {
    final chunk = DocumentTextChunk(
      documentId: 'doc',
      location: DocumentLocation(
        scheme: 'pdf',
        data: const <String, Object?>{'page': 4},
      ),
      text: 'abcd',
      coordinateSpace: DocumentCoordinateSpace.pdfPagePoints,
      extentWidth: 100,
      extentHeight: 100,
      rotationDegrees: 0,
      characterBounds: const <DocumentRect>[
        DocumentRect(left: 0, top: 10, right: 5, bottom: 0),
        DocumentRect(left: 5, top: 10, right: 10, bottom: 0),
        DocumentRect(left: 10, top: 10, right: 15, bottom: 0),
        DocumentRect(left: 0, top: 25, right: 5, bottom: 15),
      ],
      fragments: const <DocumentTextFragment>[],
    );

    final geometry = sourceGeometryForRange(chunk, start: 1, end: 4);

    expect(geometry, hasLength(2));
    expect(geometry.first['page'], 4);
    expect(geometry.first['start'], 1);
    expect(geometry.first['end'], 4);
    expect(geometry.first['left'], 5.0);
    expect(geometry.first['right'], 15.0);
    expect(geometry.last['top'], 25.0);
  });

  test('returns no geometry for an empty range', () {
    final chunk = DocumentTextChunk(
      documentId: 'doc',
      location: DocumentLocation(
        scheme: 'pdf',
        data: const <String, Object?>{'page': 1},
      ),
      text: 'a',
      coordinateSpace: DocumentCoordinateSpace.pdfPagePoints,
      extentWidth: 10,
      extentHeight: 10,
      rotationDegrees: 0,
      characterBounds: const <DocumentRect>[
        DocumentRect(left: 0, top: 10, right: 5, bottom: 0),
      ],
      fragments: const <DocumentTextFragment>[],
    );

    expect(sourceGeometryForRange(chunk, start: 0, end: 0), isEmpty);
  });
}
