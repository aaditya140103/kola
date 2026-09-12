import 'package:drift/drift.dart';
import 'package:kola/core/database/database_serialization.dart';
import 'package:kola/core/database/kola_database.dart';
import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/search/domain/search_models.dart';
import 'package:kola/features/search/domain/search_repository.dart';

final class DriftSearchRepository implements SearchRepository {
  DriftSearchRepository(this._database);

  final KolaDatabase _database;

  @override
  Future<SearchIndexStatus?> getIndexStatus(String documentId) async {
    final List<QueryRow> rows = await _database.customSelect(
      '''
      SELECT document_id, indexed_revision, extractor_version, indexed_at
      FROM document_search_state
      WHERE document_id = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(documentId)],
    ).get();
    if (rows.isEmpty) return null;
    final Map<String, Object?> data = rows.single.data;
    return SearchIndexStatus(
      documentId: data['document_id']! as String,
      indexedRevision: data['indexed_revision']! as int,
      extractorVersion: data['extractor_version']! as String,
      indexedAt: DatabaseSerialization.dateTime(data['indexed_at']),
    );
  }

  @override
  Future<void> replaceDocumentIndex({
    required KolaDocument document,
    required String extractorVersion,
    required List<IndexChunk> chunks,
  }) async {
    await _database.transaction(() async {
      await _database.customStatement(
        'DELETE FROM document_search WHERE document_id = ?',
        <Object?>[document.id],
      );

      final DocumentLocation metadataLocation = DocumentLocation(
        scheme: 'document',
        data: const <String, Object?>{},
        label: document.metadata.title,
      );
      final String metadataText = <String>[
        document.metadata.title,
        if (document.metadata.subtitle != null) document.metadata.subtitle!,
        ...document.metadata.authors,
      ].join(' ');
      await _insertRow(
        documentId: document.id,
        location: metadataLocation,
        sectionLabel: 'Document',
        kind: SearchHitKind.metadata,
        text: metadataText,
      );

      for (final IndexChunk chunk in chunks) {
        if (chunk.text.trim().isEmpty) continue;
        await _insertRow(
          documentId: document.id,
          location: chunk.location,
          sectionLabel: chunk.sectionLabel,
          kind: SearchHitKind.content,
          text: chunk.text,
        );
      }

      await _database.customStatement(
        '''
        INSERT INTO document_search_state (
          document_id, indexed_revision, extractor_version, indexed_at
        ) VALUES (?, ?, ?, ?)
        ON CONFLICT(document_id) DO UPDATE SET
          indexed_revision = excluded.indexed_revision,
          extractor_version = excluded.extractor_version,
          indexed_at = excluded.indexed_at
        ''',
        <Object?>[
          document.id,
          document.revision,
          extractorVersion,
          DatabaseSerialization.encodeDateTime(DateTime.now().toUtc()),
        ],
      );
    });
  }

  Future<void> _insertRow({
    required String documentId,
    required DocumentLocation location,
    required String? sectionLabel,
    required SearchHitKind kind,
    required String text,
  }) {
    return _database.customStatement(
      '''
      INSERT INTO document_search (
        document_id, locator_json, section_label, kind, body
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      <Object?>[
        documentId,
        DatabaseSerialization.encodeLocation(location),
        sectionLabel,
        kind.name,
        text,
      ],
    );
  }

  @override
  Future<void> deleteDocumentIndex(String documentId) async {
    await _database.transaction(() async {
      await _database.customStatement(
        'DELETE FROM document_search WHERE document_id = ?',
        <Object?>[documentId],
      );
      await _database.customStatement(
        'DELETE FROM document_search_state WHERE document_id = ?',
        <Object?>[documentId],
      );
    });
  }

  @override
  Future<List<SearchHit>> search(
    String query, {
    String? documentId,
    SearchHitKind? kind,
    int limit = 50,
  }) async {
    final String match = _compileFtsQuery(query);
    if (match.isEmpty || limit <= 0) return const <SearchHit>[];

    final String documentClause = documentId == null
        ? ''
        : 'AND document_search.document_id = ?';
    final String kindClause = kind == null ? '' : 'AND document_search.kind = ?';
    final List<Variable<Object>> variables = <Variable<Object>>[
      Variable<String>(match),
      if (documentId != null) Variable<String>(documentId),
      if (kind != null) Variable<String>(kind.name),
      Variable<int>(limit),
    ];

    final List<QueryRow> rows = await _database.customSelect(
      '''
      SELECT
        document_search.document_id,
        documents.title AS document_title,
        document_search.locator_json,
        document_search.section_label,
        document_search.kind,
        snippet(document_search, 4, '[[', ']]', ' … ', 22) AS snippet,
        bm25(document_search) AS rank
      FROM document_search
      JOIN documents ON documents.id = document_search.document_id
      WHERE document_search MATCH ?
        $documentClause
        $kindClause
      ORDER BY rank ASC
      LIMIT ?
      ''',
      variables: variables,
    ).get();

    return List<SearchHit>.unmodifiable(rows.map(_hitFromRow));
  }

  SearchHit _hitFromRow(QueryRow row) {
    final Map<String, Object?> data = row.data;
    return SearchHit(
      documentId: data['document_id']! as String,
      documentTitle: data['document_title']! as String,
      location: DatabaseSerialization.decodeLocation(data['locator_json']) ??
          DocumentLocation(
            scheme: 'document',
            data: const <String, Object?>{},
          ),
      snippet: data['snippet'] as String? ?? '',
      kind: DatabaseSerialization.enumValue(
        SearchHitKind.values,
        data['kind'],
        SearchHitKind.content,
      ),
      rank: (data['rank'] as num?)?.toDouble() ?? 0.0,
      sectionLabel: data['section_label'] as String?,
    );
  }

  static String _compileFtsQuery(String input) {
    final Iterable<String> terms = input
        .trim()
        .split(RegExp(r'\s+'))
        .map((String term) => term.trim())
        .where((String term) => term.isNotEmpty);
    return terms
        .map((String term) => '"${term.replaceAll('"', '""')}"')
        .join(' AND ');
  }
}
