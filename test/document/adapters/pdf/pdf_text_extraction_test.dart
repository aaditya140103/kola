import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdfrx_pdf_adapter.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:kola/document/text/document_text_geometry.dart';

import '../../../support/simple_pdf.dart';
import '../../../support/native_pdfium.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestPdfium);

  test(
    'extracts source-linked text geometry and index chunks from a PDF',
    () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'kola-pdf-text-',
      );
      final File pdfFile = File('${tempDirectory.path}/sample.pdf');
      await pdfFile.writeAsBytes(buildSimplePdf('Hello Kola'));

      const PdfrxPdfAdapter adapter = PdfrxPdfAdapter(DocumentSourceResolver());
      final DateTime now = DateTime.utc(2026, 9, 12, 9);
      final KolaDocument document = KolaDocument(
        id: 'sha256:test-pdf-text',
        source: DocumentSource(
          kind: DocumentSourceKind.linkedFile,
          uri: pdfFile.uri,
        ),
        format: DocumentFormat.pdf,
        metadata: const DocumentMetadata(title: 'Sample'),
        importedAt: now,
        updatedAt: now,
      );

      final DocumentHandle handle = await adapter.open(document);
      try {
        final List<DocumentTextChunk> textChunks = await adapter
            .extractTextGeometry(handle)
            .toList();

        expect(textChunks, hasLength(1));
        final DocumentTextChunk page = textChunks.single;
        expect(page.documentId, document.id);
        expect(page.location.scheme, 'pdf');
        expect(page.location.data['page'], 1);
        expect(page.text, contains('Hello Kola'));
        expect(page.coordinateSpace, DocumentCoordinateSpace.pdfPagePoints);
        expect(page.extentWidth, greaterThan(0));
        expect(page.extentHeight, greaterThan(0));
        expect(page.characterBounds, isNotEmpty);
        expect(page.fragments, isNotEmpty);
        expect(page.fragments.map(page.textFor).join(), contains('Hello Kola'));

        final List<IndexChunk> indexChunks = await adapter
            .extractIndexableContent(handle)
            .toList();
        expect(indexChunks, hasLength(1));
        expect(indexChunks.single.text, contains('Hello Kola'));
        expect(indexChunks.single.location.data['page'], 1);
        expect(indexChunks.single.sectionLabel, 'Page 1');

        final List<GraphChunk> graphChunks = await adapter
            .buildDocumentGraph(handle, const GraphBuildOptions())
            .toList();
        expect(graphChunks, hasLength(1));
        expect(graphChunks.single.flowQuality, FlowQuality.extracted);
        expect(graphChunks.single.isFinal, isTrue);
        expect(
          graphChunks.single.nodes.single.kind,
          KolaNodeKind.sourceVisualBlock,
        );
        expect(graphChunks.single.nodes.single.text, contains('Hello Kola'));
      } finally {
        await handle.close();
        await tempDirectory.delete(recursive: true);
      }
    },
  );
}
