import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../support/simple_pdf.dart';
import '../../../support/native_pdfium.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestPdfium);

  testWidgets(
    'managed PDF renders actual pages, exposes outline, and survives provider rebuilds',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = Directory.systemTemp.createTempSync('kola-viewer-');
      final file = File('${directory.path}/sample.pdf');
      file.writeAsBytesSync(
        buildSimplePdf('Hello Kola', outlineTitle: 'Introduction'),
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
        attempt < 100 && find.text('Page 1 of 1').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Page 1 of 1'), findsOneWidget);
      final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
      expect(viewer.controller!.isReady, isTrue);
      expect(viewer.controller!.document.pages, hasLength(1));
      final page = viewer.controller!.document.pages.first;
      final image = await tester.runAsync(
        () => page.render(fullWidth: 306, fullHeight: 396),
      );
      expect(image, isNotNull);
      expect(image!.pixels, isNotEmpty);
      image.dispose();

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
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Introduction'), findsNothing);

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
      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => directory.delete(recursive: true));
    },
  );
}
