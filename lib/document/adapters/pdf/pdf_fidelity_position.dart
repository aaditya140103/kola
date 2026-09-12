import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';

abstract final class PdfFidelityPosition {
  static int initialPageNumber(FidelityViewState? state) {
    final DocumentLocation? location = state?.location;
    if (location?.scheme != 'pdf') return 1;

    final Object? rawPage = location!.data['page'];
    if (rawPage is int && rawPage > 0) return rawPage;
    if (rawPage is num && rawPage > 0) return rawPage.toInt();
    return 1;
  }

  static double? initialZoom(FidelityViewState? state) {
    final double? zoom = state?.zoom;
    if (zoom == null || !zoom.isFinite || zoom <= 0) return null;
    return zoom;
  }

  static FidelityViewState fromViewer({
    required int pageNumber,
    required int pageCount,
    required double zoom,
  }) {
    final int safePageCount = pageCount < 1 ? 1 : pageCount;
    final int safePage = pageNumber.clamp(1, safePageCount);
    final double progress = (safePage / safePageCount).clamp(0.0, 1.0);
    final double safeZoom = zoom.isFinite && zoom > 0 ? zoom : 1.0;

    return FidelityViewState(
      location: DocumentLocation(
        scheme: 'pdf',
        data: <String, Object?>{'page': safePage},
        label: 'Page $safePage',
      ),
      positionProgress: progress,
      zoom: safeZoom,
    );
  }
}
