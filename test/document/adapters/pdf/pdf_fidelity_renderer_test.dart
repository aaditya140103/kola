import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../support/native_pdfium.dart';
import '../../../support/simple_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestPdfium);

  testWidgets(
    'managed PDF renders pages, fits view, navigates structure, and survives rebuilds',
    (tester) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = Directory.systemTemp.createTempSync('kola-viewer-');
      final file = File('${directory.path}/sample.pdf');
      file.writeAsBytesSync(
        buildPdfWithPages(
          <String>['Hello Kola', 'Second page'],
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
        attempt < 100 && find.text('Page 1 of 2').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Page 1 of 2'), findsOneWidget);
      final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
      final PdfViewerController controller = viewer.controller!;
      expect(controller.isReady, isTrue);
      expect(controller.document.pages, hasLength(2));
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

      expect(find.byTooltip('Pages'), findsOneWidget);
      await tester.tap(find.byTooltip('Pages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey<String>('pdf-thumbnail-1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('pdf-thumbnail-2')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('pdf-thumbnail-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (
        var attempt = 0;
        attempt < 50 && find.text('Page 2 of 2').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('Page 2 of 2'), findsOneWidget);

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
        attempt < 50 && find.text('Page 1 of 2').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('Page 1 of 2'), findsOneWidget);

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
      expect(find.text('Page 1 of 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => directory.delete(recursive: true));
    },
  );
}
