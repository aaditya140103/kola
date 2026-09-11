import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/document/adapters/pdf/pdfrx_pdf_adapter.dart';
import 'package:kola/document/adapters/pdf/pdfrx_pdf_fidelity_renderer.dart';
import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/document/source/document_source_resolver.dart';

final documentSourceResolverProvider = Provider<DocumentSourceResolver>((ref) {
  return const DocumentSourceResolver();
});

final pdfDocumentAdapterProvider = Provider<DocumentAdapter>((ref) {
  return PdfrxPdfAdapter(ref.watch(documentSourceResolverProvider));
});

final formatRegistryProvider = Provider<FormatRegistry>((ref) {
  return FormatRegistry(<DocumentAdapter>[
    ref.watch(pdfDocumentAdapterProvider),
  ]);
});

final fidelityRendererRegistryProvider = Provider<FidelityRendererRegistry>((ref) {
  return FidelityRendererRegistry(<DocumentFidelityRenderer>[
    PdfrxPdfFidelityRenderer(ref.watch(documentSourceResolverProvider)),
  ]);
});
