import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

const double pdfTwoPageSpreadMinWidth = 840;

PdfPageLayout buildPdfFacingPagesLayout(
  List<PdfPage> pages,
  PdfViewerParams params,
) {
  if (pages.isEmpty) {
    return PdfPageLayout(
      pageLayouts: const <Rect>[],
      documentSize: Size.zero,
    );
  }

  final double maxPageWidth = pages.fold<double>(
    0,
    (double previous, PdfPage page) => math.max(previous, page.width),
  );
  final List<Rect> pageLayouts = <Rect>[];

  // LTR facing-page layout with page 1 treated as a cover on the right.
  const int coverOffset = 1;
  double y = params.margin;

  for (int index = 0; index < pages.length; index++) {
    final PdfPage page = pages[index];
    final int position = index + coverOffset;
    final bool isLeftPage = (position & 1) == 0;
    final int otherSideIndex = (position ^ 1) - coverOffset;
    final double rowHeight =
        otherSideIndex >= 0 && otherSideIndex < pages.length
        ? math.max(page.height, pages[otherSideIndex].height)
        : page.height;

    pageLayouts.add(
      Rect.fromLTWH(
        isLeftPage
            ? maxPageWidth + params.margin - page.width
            : params.margin * 2 + maxPageWidth,
        y + (rowHeight - page.height) / 2,
        page.width,
        page.height,
      ),
    );

    if ((position & 1) == 1 || index + 1 == pages.length) {
      y += rowHeight + params.margin;
    }
  }

  return PdfPageLayout(
    pageLayouts: pageLayouts,
    documentSize: Size(
      (params.margin + maxPageWidth) * 2 + params.margin,
      y,
    ),
  );
}
