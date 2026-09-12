import 'package:drift/drift.dart';
import 'package:kola/core/database/database_serialization.dart';
import 'package:kola/core/database/kola_database.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/library/domain/document_repository.dart';

final class DriftDocumentRepository implements DocumentRepository {
  DriftDocumentRepository(this._database);

  final KolaDatabase _database;

  @override
  Stream<List<KolaDocument>> watchAll() {
    return _database
        .customSelect(
          '''
          SELECT *
          FROM documents
          ORDER BY
            CASE WHEN last_opened_at IS NULL THEN 1 ELSE 0 END,
            last_opened_at DESC,
            imported_at DESC
          ''',
          readsFrom: {_database.documents},
        )
        .watch()
        .map(
          (List<QueryRow> rows) => List<KolaDocument>.unmodifiable(
            rows.map(_documentFromRow),
          ),
        );
  }

  @override
  Future<KolaDocument?> getById(String id) async {
    final List<QueryRow> rows = await _database
        .customSelect(
          'SELECT * FROM documents WHERE id = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<String>(id)],
          readsFrom: {_database.documents},
        )
        .get();

    return rows.isEmpty ? null : _documentFromRow(rows.single);
  }

  @override
  Future<void> upsert(KolaDocument document) async {
    await _database.customStatement(
      '''
      INSERT INTO documents (
        id, content_hash, source_kind, source_uri, managed_path, format,
        title, subtitle, authors_json, language, cover_cache_key, file_size,
        imported_at, last_opened_at, support_status, parser_version,
        revision, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        content_hash = excluded.content_hash,
        source_kind = excluded.source_kind,
        source_uri = excluded.source_uri,
        managed_path = excluded.managed_path,
        format = excluded.format,
        title = excluded.title,
        subtitle = excluded.subtitle,
        authors_json = excluded.authors_json,
        language = excluded.language,
        cover_cache_key = excluded.cover_cache_key,
        file_size = excluded.file_size,
        imported_at = excluded.imported_at,
        last_opened_at = excluded.last_opened_at,
        support_status = excluded.support_status,
        parser_version = excluded.parser_version,
        revision = excluded.revision,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        document.id,
        document.contentHash,
        document.source.kind.name,
        document.source.uri.toString(),
        document.source.managedPath,
        document.format.name,
        document.metadata.title,
        document.metadata.subtitle,
        DatabaseSerialization.encodeStrings(document.metadata.authors),
        document.metadata.language,
        document.metadata.coverCacheKey,
        document.fileSize,
        DatabaseSerialization.encodeDateTime(document.importedAt),
        DatabaseSerialization.encodeNullableDateTime(document.lastOpenedAt),
        document.supportStatus.name,
        document.parserVersion,
        document.revision,
        DatabaseSerialization.encodeDateTime(document.updatedAt),
      ],
    );
    _database.markTablesUpdated([_database.documents]);
  }

  @override
  Future<void> markOpened(String id, DateTime openedAt) async {
    await _database.customStatement(
      'UPDATE documents SET last_opened_at = ? WHERE id = ?',
      <Object?>[
        DatabaseSerialization.encodeDateTime(openedAt),
        id,
      ],
    );
    _database.markTablesUpdated([_database.documents]);
  }

  @override
  Future<void> remove(String id) async {
    await _database.customStatement(
      'DELETE FROM documents WHERE id = ?',
      <Object?>[id],
    );
    _database.markTablesUpdated([
      _database.documents,
      _database.readingStates,
      _database.readingCoverage,
      _database.readingSessions,
      _database.annotations,
      _database.bookmarks,
      _database.plannedReadingItems,
    ]);
  }

  KolaDocument _documentFromRow(QueryRow row) {
    final Map<String, Object?> data = row.data;
    return KolaDocument(
      id: data['id']! as String,
      contentHash: data['content_hash'] as String?,
      source: DocumentSource(
        kind: DatabaseSerialization.enumValue(
          DocumentSourceKind.values,
          data['source_kind'],
          DocumentSourceKind.linkedFile,
        ),
        uri: Uri.parse(data['source_uri']! as String),
        managedPath: data['managed_path'] as String?,
      ),
      format: DatabaseSerialization.enumValue(
        DocumentFormat.values,
        data['format'],
        DocumentFormat.unknown,
      ),
      metadata: DocumentMetadata(
        title: data['title']! as String,
        subtitle: data['subtitle'] as String?,
        authors: DatabaseSerialization.decodeStrings(data['authors_json']),
        language: data['language'] as String?,
        coverCacheKey: data['cover_cache_key'] as String?,
      ),
      fileSize: data['file_size'] as int?,
      importedAt: DatabaseSerialization.dateTime(data['imported_at']),
      lastOpenedAt: DatabaseSerialization.nullableDateTime(
        data['last_opened_at'],
      ),
      supportStatus: DatabaseSerialization.enumValue(
        DocumentSupportStatus.values,
        data['support_status'],
        DocumentSupportStatus.supported,
      ),
      parserVersion: data['parser_version'] as String?,
      revision: data['revision'] as int? ?? 1,
      updatedAt: DatabaseSerialization.dateTime(data['updated_at']),
    );
  }
}
