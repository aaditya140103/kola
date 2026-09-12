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
    expect(capabilities.flowMode, isFalse);
    expect(capabilities.areaAnnotations, isFalse);
    expect(capabilities.inkAnnotations, isFalse);
  });
}
