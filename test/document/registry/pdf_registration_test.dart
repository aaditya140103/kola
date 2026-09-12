import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/adapters/pdf/pdfrx_pdf_adapter.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/document/source/document_source_resolver.dart';

void main() {
  test('PDF adapter advertises only integrated reader capabilities', () {
    final FormatRegistry registry = FormatRegistry(<PdfrxPdfAdapter>[
      const PdfrxPdfAdapter(DocumentSourceResolver()),
    ]);

    final capabilities = registry.capabilitiesFor(DocumentFormat.pdf);

    expect(capabilities, isNotNull);
    expect(capabilities!.fidelityView, isTrue);
    expect(capabilities.textSearch, isTrue);
    expect(capabilities.textSelection, isTrue);
    expect(capabilities.textAnnotations, isTrue);
    expect(capabilities.outline, isTrue);
    expect(capabilities.flowMode, isFalse);
    expect(capabilities.areaAnnotations, isFalse);
    expect(capabilities.inkAnnotations, isFalse);
  });

  test('managed PDF fallback title uses the original source name', () async {
    final Directory directory = Directory.systemTemp.createTempSync(
      'kola-pdf-metadata-',
    );
    addTearDown(() async {
      await directory.delete(recursive: true);
    });
    final File managed = File(
      '${directory.path}/8f14e45fceea167a5a36dedd4bea2543.pdf',
    );
    await managed.writeAsString('%PDF-1.7\nmetadata fallback');

    final DocumentMetadata metadata = await const PdfrxPdfAdapter(
      DocumentSourceResolver(),
    ).readMetadata(
      DocumentSource(
        kind: DocumentSourceKind.managedCopy,
        uri: Uri.file('${directory.path}/Research Notes.pdf'),
        managedPath: managed.path,
      ),
    );

    expect(metadata.title, 'Research Notes');
  });
}
