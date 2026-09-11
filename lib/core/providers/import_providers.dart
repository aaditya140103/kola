import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/repository_providers.dart';
import 'package:kola/document/import/document_file_picker.dart';
import 'package:kola/document/import/document_fingerprint_service.dart';
import 'package:kola/document/import/document_format_detector.dart';
import 'package:kola/document/import/document_import_service.dart';
import 'package:kola/document/import/document_source_storage.dart';
import 'package:kola/document/registry/format_registry.dart';

final formatRegistryProvider = Provider<FormatRegistry>((ref) {
  return FormatRegistry();
});

final documentFilePickerProvider = Provider<DocumentFilePicker>((ref) {
  return const NativeDocumentFilePicker();
});

final documentFingerprintServiceProvider = Provider<DocumentFingerprintService>((
  ref,
) {
  return const DocumentFingerprintService();
});

final documentFormatDetectorProvider = Provider<DocumentFormatDetector>((ref) {
  return const DocumentFormatDetector();
});

final documentSourceStorageProvider = Provider<DocumentSourceStorage>((ref) {
  return const LocalDocumentSourceStorage();
});

final documentImportServiceProvider = Provider<DocumentImportService>((ref) {
  return DocumentImportService(
    documents: ref.watch(documentRepositoryProvider),
    picker: ref.watch(documentFilePickerProvider),
    fingerprints: ref.watch(documentFingerprintServiceProvider),
    formatDetector: ref.watch(documentFormatDetectorProvider),
    sourceStorage: ref.watch(documentSourceStorageProvider),
    formatRegistry: ref.watch(formatRegistryProvider),
  );
});
