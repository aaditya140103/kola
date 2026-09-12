import 'dart:io';

import 'package:kola/document/import/document_file_picker.dart';
import 'package:kola/document/import/document_fingerprint_service.dart';
import 'package:kola/document/import/document_format_detector.dart';
import 'package:kola/document/import/document_source_storage.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_match.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/features/library/domain/document_repository.dart';

enum DocumentImportStatus {
  imported,
  alreadyPresent,
  sourceUpdated,
  sourceRepaired,
}

final class DocumentImportResult {
  const DocumentImportResult({
    required this.status,
    required this.document,
    required this.formatMatch,
  });

  final DocumentImportStatus status;
  final KolaDocument document;
  final FormatMatch formatMatch;
}

final class DocumentImportService {
  DocumentImportService({
    required DocumentRepository documents,
    required DocumentFilePicker picker,
    required DocumentFingerprintService fingerprints,
    required DocumentFormatDetector formatDetector,
    required DocumentSourceStorage sourceStorage,
    required FormatRegistry formatRegistry,
    DateTime Function()? now,
  }) : this._(
         documents,
         picker,
         fingerprints,
         formatDetector,
         sourceStorage,
         formatRegistry,
         now ?? _utcNow,
       );

  DocumentImportService._(
    this._documents,
    this._picker,
    this._fingerprints,
    this._formatDetector,
    this._sourceStorage,
    this._formatRegistry,
    this._now,
  );

  final DocumentRepository _documents;
  final DocumentFilePicker _picker;
  final DocumentFingerprintService _fingerprints;
  final DocumentFormatDetector _formatDetector;
  final DocumentSourceStorage _sourceStorage;
  final FormatRegistry _formatRegistry;
  final DateTime Function() _now;

  Future<DocumentImportResult?> pickAndImport({
    DocumentImportMode mode = DocumentImportMode.managedCopy,
  }) async {
    final PickedDocumentFile? picked = await _picker.pickSingle();
    if (picked == null) return null;
    return importPath(
      picked.path,
      displayName: picked.name,
      mode: mode,
    );
  }

  Future<DocumentImportResult> importPath(
    String path, {
    String? displayName,
    DocumentImportMode mode = DocumentImportMode.managedCopy,
  }) async {
    final String normalizedPath = File(path).absolute.path;

    // Detect first, then fingerprint. Starting independent futures here can leave
    // one future unobserved if the other fails first, which surfaces as an
    // unrelated asynchronous error during import.
    final FormatMatch match = await _formatDetector.detect(normalizedPath);
    if (!match.isRecognized) {
      throw UnsupportedDocumentFormatException(normalizedPath);
    }
    final DocumentFingerprint fingerprint = await _fingerprints.fingerprint(
      normalizedPath,
    );

    final KolaDocument? existing = await _documents.getById(
      fingerprint.stableId,
    );
    final Uri originalUri = Uri.file(normalizedPath);
    bool repairingManagedCopy = false;
    if (existing != null &&
        existing.source.kind == _sourceKindFor(mode) &&
        existing.source.uri == originalUri) {
      repairingManagedCopy =
          mode == DocumentImportMode.managedCopy &&
          !await _managedCopyExists(existing.source);
      if (!repairingManagedCopy) {
        return DocumentImportResult(
          status: DocumentImportStatus.alreadyPresent,
          document: existing,
          formatMatch: match,
        );
      }
    }

    final DocumentSource source = await _sourceStorage.prepare(
      sourcePath: normalizedPath,
      fingerprint: fingerprint,
      mode: mode,
    );
    final DocumentAdapter? adapter = _formatRegistry.adapterFor(match.format);
    final DocumentMetadata metadata = await _metadataFor(
      adapter: adapter,
      source: source,
      existing: existing,
      fallbackName: displayName ?? _fileName(normalizedPath),
    );
    final DateTime now = _now().toUtc();

    final KolaDocument document = KolaDocument(
      id: fingerprint.stableId,
      contentHash: fingerprint.stableId,
      source: source,
      format: match.format,
      metadata: metadata,
      fileSize: fingerprint.fileSize,
      importedAt: existing?.importedAt ?? now,
      lastOpenedAt: existing?.lastOpenedAt,
      supportStatus: adapter == null
          ? DocumentSupportStatus.partial
          : DocumentSupportStatus.supported,
      parserVersion: existing?.parserVersion,
      revision: existing == null ? 1 : existing.revision + 1,
      updatedAt: now,
    );

    await _documents.upsert(document);
    return DocumentImportResult(
      status: existing == null
          ? DocumentImportStatus.imported
          : repairingManagedCopy
          ? DocumentImportStatus.sourceRepaired
          : DocumentImportStatus.sourceUpdated,
      document: document,
      formatMatch: match,
    );
  }

  Future<DocumentMetadata> _metadataFor({
    required DocumentAdapter? adapter,
    required DocumentSource source,
    required KolaDocument? existing,
    required String fallbackName,
  }) async {
    if (adapter != null) {
      return adapter.readMetadata(source);
    }
    if (existing != null) return existing.metadata;
    return DocumentMetadata(title: _titleFromFileName(fallbackName));
  }

  static Future<bool> _managedCopyExists(DocumentSource source) async {
    final String? managedPath = source.managedPath;
    if (managedPath == null || managedPath.isEmpty) return false;
    return File(managedPath).exists();
  }

  static DocumentSourceKind _sourceKindFor(DocumentImportMode mode) {
    return switch (mode) {
      DocumentImportMode.managedCopy => DocumentSourceKind.managedCopy,
      DocumentImportMode.linkedFile => DocumentSourceKind.linkedFile,
    };
  }

  static String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;

  static String _titleFromFileName(String name) {
    final int dot = name.lastIndexOf('.');
    final String title = dot > 0 ? name.substring(0, dot) : name;
    return title.trim().isEmpty ? 'Untitled document' : title.trim();
  }

  static DateTime _utcNow() => DateTime.now().toUtc();
}

final class UnsupportedDocumentFormatException implements Exception {
  const UnsupportedDocumentFormatException(this.path);

  final String path;

  @override
  String toString() => 'UnsupportedDocumentFormatException: $path';
}
