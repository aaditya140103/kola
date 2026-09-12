import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdf_fidelity_position.dart';
import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';

void main() {
  group('PdfFidelityPosition', () {
    test('restores page and zoom from a pdf locator', () {
      const FidelityViewState state = FidelityViewState(
        location: DocumentLocation(
          scheme: 'pdf',
          data: <String, Object?>{'page': 37},
          label: 'Page 37',
        ),
        positionProgress: 0.37,
        zoom: 1.8,
      );

      expect(PdfFidelityPosition.initialPageNumber(state), 37);
      expect(PdfFidelityPosition.initialZoom(state), 1.8);
    });

    test('ignores non-pdf locators for page restoration', () {
      const FidelityViewState state = FidelityViewState(
        location: DocumentLocation(
          scheme: 'epub',
          data: <String, Object?>{'chapter': 4},
        ),
        positionProgress: 0.5,
        zoom: 1.0,
      );

      expect(PdfFidelityPosition.initialPageNumber(state), 1);
    });

    test('converts viewer state into stable pdf source location', () {
      final FidelityViewState state = PdfFidelityPosition.fromViewer(
        pageNumber: 25,
        pageCount: 100,
        zoom: 1.5,
      );

      expect(state.location?.scheme, 'pdf');
      expect(state.location?.data['page'], 25);
      expect(state.location?.label, 'Page 25');
      expect(state.positionProgress, 0.25);
      expect(state.zoom, 1.5);
    });

    test('clamps invalid page and zoom values', () {
      final FidelityViewState state = PdfFidelityPosition.fromViewer(
        pageNumber: 999,
        pageCount: 10,
        zoom: double.nan,
      );

      expect(state.location?.data['page'], 10);
      expect(state.positionProgress, 1.0);
      expect(state.zoom, 1.0);
    });
  });
}
