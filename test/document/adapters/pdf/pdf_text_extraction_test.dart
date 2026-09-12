import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdfrx_pdf_adapter.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/source/document_source_resolver.dart';
import 'package:kola/document/text/document_text_geometry.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();

  final String? pdfiumPath = Platform.environment['PDFIUM_PATH'];
  final bool hasNativePdfium = pdfiumPath != null && pdfiumPath.isNotEmpty;

  test(
    'extracts source-linked text geometry and index chunks from a PDF',
    () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'kola-pdf-text-',
      );
      final File pdfFile = File('${tempDirectory.path}/sample.pdf');
      await pdfFile.writeAsBytes(_buildSimplePdf('Hello Kola'));

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
    skip: hasNativePdfium
        ? false
        : 'Set PDFIUM_PATH to a native libpdfium to run the real engine integration test.',
  );
}

List<int> _buildSimplePdf(String text) {
  final String escaped = text
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
  final String content = 'BT\n/F1 18 Tf\n72 720 Td\n($escaped) Tj\nET\n';

  final List<String> objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Length ${ascii.encode(content).length} >>\nstream\n${content}endstream',
  ];

  final StringBuffer buffer = StringBuffer('%PDF-1.4\n');
  final List<int> offsets = <int>[];
  for (int index = 0; index < objects.length; index += 1) {
    offsets.add(buffer.length);
    buffer
      ..writeln('${index + 1} 0 obj')
      ..writeln(objects[index])
      ..writeln('endobj');
  }

  final int xrefOffset = buffer.length;
  buffer
    ..writeln('xref')
    ..writeln('0 ${objects.length + 1}')
    ..writeln('0000000000 65535 f ');
  for (final int offset in offsets) {
    buffer.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
  }
  buffer
    ..writeln('trailer')
    ..writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>')
    ..writeln('startxref')
    ..writeln(xrefOffset)
    ..writeln('%%EOF');

  return ascii.encode(buffer.toString());
}
