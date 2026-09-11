import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/core/database/kola_database.dart';
import 'package:kola/document/import/document_file_picker.dart';
import 'package:kola/document/import/document_fingerprint_service.dart';
import 'package:kola/document/import/document_format_detector.dart';
import 'package:kola/document/import/document_import_service.dart';
import 'package:kola/document/import/document_source_storage.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/features/library/data/drift_document_repository.dart';

void main() {
  late Directory tempDirectory;
  late KolaDatabase database;
  late DriftDocumentRepository documents;
  late DocumentImportService importer;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('kola-import-test-');
    database = KolaDatabase(NativeDatabase.memory());
    documents = DriftDocumentRepository(database);
    importer = DocumentImportService(
      documents: documents,
      picker: const _NeverDocumentPicker(),
      fingerprints: const DocumentFingerprintService(),
      formatDetector: const DocumentFormatDetector(),
      sourceStorage: const _LinkedTestStorage(),
      formatRegistry: FormatRegistry(),
      now: () => DateTime.utc(2026, 9, 12, 3, 30),
    );
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test('a real file becomes a persistent Kola document', () async {
    final File file = File('${tempDirectory.path}/paper.pdf');
    await file.writeAsString('%PDF-1.7\nexample');

    final DocumentImportResult result = await importer.importPath(
      file.path,
      mode: DocumentImportMode.linkedFile,
    );

    expect(result.status, DocumentImportStatus.imported);
    expect(result.document.format, DocumentFormat.pdf);
    expect(result.document.metadata.title, 'paper');
    expect(result.document.source.kind, DocumentSourceKind.linkedFile);
    expect(result.document.contentHash, startsWith('sha256:'));
    expect(result.document.id, result.document.contentHash);
    expect(result.document.supportStatus, DocumentSupportStatus.partial);

    final KolaDocument? stored = await documents.getById(result.document.id);
    expect(stored?.metadata.title, 'paper');
    expect(stored?.fileSize, await file.length());
  });

  test('re-importing the same source is idempotent', () async {
    final File file = File('${tempDirectory.path}/book.pdf');
    await file.writeAsString('%PDF-1.7\nsame bytes');

    final DocumentImportResult first = await importer.importPath(
      file.path,
      mode: DocumentImportMode.linkedFile,
    );
    final DocumentImportResult second = await importer.importPath(
      file.path,
      mode: DocumentImportMode.linkedFile,
    );

    expect(first.status, DocumentImportStatus.imported);
    expect(second.status, DocumentImportStatus.alreadyPresent);
    expect(second.document.id, first.document.id);
    expect((await documents.watchAll().first).length, 1);
  });

  test('the same content at a new path relinks one document identity', () async {
    final File firstPath = File('${tempDirectory.path}/original.pdf');
    final File movedPath = File('${tempDirectory.path}/moved.pdf');
    const String bytes = '%PDF-1.7\nportable identity';
    await firstPath.writeAsString(bytes);
    await movedPath.writeAsString(bytes);

    final DocumentImportResult first = await importer.importPath(
      firstPath.path,
      mode: DocumentImportMode.linkedFile,
    );
    final DocumentImportResult moved = await importer.importPath(
      movedPath.path,
      mode: DocumentImportMode.linkedFile,
    );

    expect(moved.status, DocumentImportStatus.sourceUpdated);
    expect(moved.document.id, first.document.id);
    expect(moved.document.source.uri, Uri.file(movedPath.absolute.path));
    expect((await documents.watchAll().first).length, 1);
  });

  test('unrecognized files are rejected without library mutation', () async {
    final File file = File('${tempDirectory.path}/unknown.bin');
    await file.writeAsBytes(<int>[0, 1, 2, 3, 4]);

    await expectLater(
      importer.importPath(file.path, mode: DocumentImportMode.linkedFile),
      throwsA(isA<UnsupportedDocumentFormatException>()),
    );
    expect(await documents.watchAll().first, isEmpty);
  });
}

final class _NeverDocumentPicker implements DocumentFilePicker {
  const _NeverDocumentPicker();

  @override
  Future<PickedDocumentFile?> pickSingle() async => null;
}

final class _LinkedTestStorage implements DocumentSourceStorage {
  const _LinkedTestStorage();

  @override
  Future<DocumentSource> prepare({
    required String sourcePath,
    required DocumentFingerprint fingerprint,
    required DocumentImportMode mode,
  }) async {
    return DocumentSource(
      kind: DocumentSourceKind.linkedFile,
      uri: Uri.file(File(sourcePath).absolute.path),
    );
  }
}
