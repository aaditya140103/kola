import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart';
import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../support/native_pdfium.dart';
import '../../../support/simple_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestPdfium);

  testWidgets(
    'managed PDF fits, adapts page layout, navigates structure, and survives rebuilds',
    (tester) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = Directory.systemTemp.createTempSync('kola-viewer-');
      final file = File('${directory.path}/sample.pdf');
      file.writeAsBytesSync(
        buildPdfWithPages(
          <String>['Hello Kola', 'Second page', 'Third page'],
          outlineTitle: 'Introduction',
        ),
      );
      final document = KolaDocument(
        id: 'sha256:viewer-test',
        source: DocumentSource(
          kind: DocumentSourceKind.managedCopy,
          uri: Uri.file('/original/removed.pdf'),
          managedPath: file.path,
        ),
        format: DocumentFormat.pdf,
        metadata: const DocumentMetadata(title: 'Sample'),
        importedAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      const renderer = PdfrxPdfFidelityRenderer(DocumentSourceResolver());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => renderer.build(context, document),
            ),
          ),
        ),
      );

      // Native file IO/rendering is real asynchronous work outside the fake clock.
      for (
        var attempt = 0;
        attempt < 100 && find.text('Page 1 of 3').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Page 1 of 3'), findsOneWidget);
      final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
      final PdfViewerController controller = viewer.controller!;
      expect(controller.isReady, isTrue);
      expect(controller.document.pages, hasLength(3));
      final page = controller.document.pages.first;
      final image = await tester.runAsync(
        () => page.render(fullWidth: 306, fullHeight: 396),
      );
      expect(image, isNotNull);
      expect(image!.pixels, isNotEmpty);
      image.dispose();

      final widthMatrix = controller.calcMatrixFitWidthForPage(pageNumber: 1);
      final heightMatrix = controller.calcMatrixFitHeightForPage(pageNumber: 1);
      expect(widthMatrix, isNotNull);
      expect(heightMatrix, isNotNull);
      final double widthZoom = widthMatrix!.getMaxScaleOnAxis();
      final double heightZoom = heightMatrix!.getMaxScaleOnAxis();
      final double pageZoom = widthZoom <= heightZoom ? widthZoom : heightZoom;
      expect(widthZoom, greaterThan(pageZoom));

      expect(find.byTooltip('Fit view'), findsOneWidget);
      await tester.tap(find.byTooltip('Fit view'));
      await tester.pumpAndSettle();
      expect(find.text('Fit width'), findsOneWidget);
      expect(find.text('Fit page'), findsOneWidget);
      await tester.tap(find.text('Fit width'));
      await tester.pumpAndSettle();
      expect(controller.currentZoom, closeTo(widthZoom, 0.01));

      await tester.tap(find.byTooltip('Fit view'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fit page'));
      await tester.pumpAndSettle();
      expect(controller.currentZoom, closeTo(pageZoom, 0.01));

      final Rect singlePage2 = controller.layout.pageLayouts[1];
      final Rect singlePage3 = controller.layout.pageLayouts[2];
      expect(singlePage3.top, greaterThan(singlePage2.bottom));
      expect(find.byTooltip('Page layout'), findsOneWidget);
      await tester.tap(find.byTooltip('Page layout'));
      await tester.pumpAndSettle();
      expect(find.text('Single page'), findsOneWidget);
      expect(find.text('Two-page spread'), findsOneWidget);
      await tester.tap(find.text('Two-page spread'));
      await tester.pump();
      for (
        var attempt = 0;
        attempt < 50 && !_hasFacingPair(controller);
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(_hasFacingPair(controller), isTrue);
      final Rect cover = controller.layout.pageLayouts[0];
      final Rect leftPage = controller.layout.pageLayouts[1];
      expect(cover.left, greaterThan(leftPage.left));
      expect(leftPage.top, greaterThanOrEqualTo(cover.bottom));

      expect(find.byTooltip('Pages'), findsOneWidget);
      await tester.tap(find.byTooltip('Pages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey<String>('pdf-thumbnail-1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('pdf-thumbnail-2')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('pdf-thumbnail-3')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('pdf-thumbnail-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (
        var attempt = 0;
        attempt < 50 && find.text('Page 2 of 3').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('Page 2 of 3'), findsOneWidget);

      for (
        var attempt = 0;
        attempt < 100 && find.byTooltip('Contents').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byTooltip('Contents'), findsOneWidget);
      await tester.tap(find.byTooltip('Contents'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Introduction'), findsOneWidget);
      await tester.tap(find.text('Introduction'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Introduction'), findsNothing);
      for (
        var attempt = 0;
        attempt < 50 && find.text('Page 1 of 3').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('Page 1 of 3'), findsOneWidget);

      tester.view.physicalSize = const Size(600, 600);
      await tester.pump();
      for (
        var attempt = 0;
        attempt < 50 && !_hasVerticalPages(controller);
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byTooltip('Page layout'), findsNothing);
      expect(_hasVerticalPages(controller), isTrue);

      tester.view.physicalSize = const Size(900, 600);
      await tester.pump();
      for (
        var attempt = 0;
        attempt < 50 && !_hasFacingPair(controller);
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byTooltip('Page layout'), findsOneWidget);
      expect(_hasFacingPair(controller), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => renderer.build(context, document),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Page 1 of 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => directory.delete(recursive: true));
    },
  );

  testWidgets(
    'fit commands and zoom actions survive transient layouts and teardown',
    (tester) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = Directory.systemTemp.createTempSync('kola-viewer-');
      final file = File('${directory.path}/sample.pdf');
      file.writeAsBytesSync(
        buildPdfWithPages(
          List<String>.generate(40, (int index) => 'Page text ${index + 1}'),
        ),
      );
      final document = KolaDocument(
        id: 'sha256:viewer-race-test',
        source: DocumentSource(
          kind: DocumentSourceKind.managedCopy,
          uri: Uri.file('/original/removed.pdf'),
          managedPath: file.path,
        ),
        format: DocumentFormat.pdf,
        metadata: const DocumentMetadata(title: 'Sample'),
        importedAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      const renderer = PdfrxPdfFidelityRenderer(DocumentSourceResolver());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => renderer.build(
                context,
                document,
                initialState: FidelityViewState(
                  location: DocumentLocation(
                    scheme: 'pdf',
                    data: const <String, Object?>{'page': 35},
                  ),
                  positionProgress: 0.0,
                  zoom: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      // Progressive loading is real asynchronous work outside the fake
      // clock; wait until the deep start page is current.
      for (
        var attempt = 0;
        attempt < 100 && find.text('Page 35 of 40').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Page 35 of 40'), findsOneWidget);

      // Fit page while progressive page layout may still be catching up
      // with the deep start position.
      await tester.tap(find.byTooltip('Fit view'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fit page'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
      final PdfViewerController controller = viewer.controller!;

      // Enable the two-page spread so a narrow resize forces a relayout.
      await tester.tap(find.byTooltip('Page layout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Two-page spread'));
      await tester.pump();
      for (
        var attempt = 0;
        attempt < 50 && !_hasFacingPair(controller);
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(_hasFacingPair(controller), isTrue);

      // Fit page while a resize-driven spread deactivation relayout is
      // still in flight.
      await tester.tap(find.byTooltip('Fit view'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(600, 600);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('Fit page'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // Fit width while the resize back re-enables the spread layout.
      await tester.tap(find.byTooltip('Fit view'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(900, 600);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('Fit width'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // Tear the viewer down while page and zoom actions are mid-flight.
      await tester.tap(find.byTooltip('Next page'));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => directory.delete(recursive: true));
    },
  );
}

bool _hasFacingPair(PdfViewerController controller) {
  if (!controller.isReady || controller.layout.pageLayouts.length < 3) {
    return false;
  }
  final Rect page2 = controller.layout.pageLayouts[1];
  final Rect page3 = controller.layout.pageLayouts[2];
  return (page2.top - page3.top).abs() < 0.01 && page2.right < page3.left;
}

bool _hasVerticalPages(PdfViewerController controller) {
  if (!controller.isReady || controller.layout.pageLayouts.length < 3) {
    return false;
  }
  final Rect page2 = controller.layout.pageLayouts[1];
  final Rect page3 = controller.layout.pageLayouts[2];
  return page3.top > page2.bottom;
}
