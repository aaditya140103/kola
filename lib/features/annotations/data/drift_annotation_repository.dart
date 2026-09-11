import 'package:drift/drift.dart';
import 'package:kola/core/database/database_serialization.dart';
import 'package:kola/core/database/kola_database.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/annotations/domain/annotation_repository.dart';

final class DriftAnnotationRepository implements AnnotationRepository {
  DriftAnnotationRepository(this._database);

  final KolaDatabase _database;

  @override
  Stream<List<Annotation>> watchForDocument(String documentId) {
    return _database
        .customSelect(
          '''
          SELECT * FROM annotations
          WHERE document_id = ? AND deleted_at IS NULL
          ORDER BY created_at ASC
          ''',
          variables: <Variable<Object>>[Variable<String>(documentId)],
          readsFrom: {_database.annotations},
        )
        .watch()
        .map(
          (List<QueryRow> rows) => List<Annotation>.unmodifiable(
            rows.map(_annotationFromRow),
          ),
        );
  }

  @override
  Future<Annotation?> getById(String id) async {
    final List<QueryRow> rows = await _database
        .customSelect(
          'SELECT * FROM annotations WHERE id = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<String>(id)],
          readsFrom: {_database.annotations},
        )
        .get();
    return rows.isEmpty ? null : _annotationFromRow(rows.single);
  }

  @override
  Future<void> upsert(Annotation annotation) {
    return _database.customStatement(
      '''
      INSERT INTO annotations (
        id, document_id, type, anchor_json, quote, note,
        semantic_label, color_token, favorite, created_at,
        updated_at, revision, deleted_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        document_id = excluded.document_id,
        type = excluded.type,
        anchor_json = excluded.anchor_json,
        quote = excluded.quote,
        note = excluded.note,
        semantic_label = excluded.semantic_label,
        color_token = excluded.color_token,
        favorite = excluded.favorite,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        revision = excluded.revision,
        deleted_at = excluded.deleted_at
      ''',
      <Object?>[
        annotation.id,
        annotation.documentId,
        annotation.type.name,
        DatabaseSerialization.encodeAnchor(annotation.anchor),
        annotation.quote,
        annotation.note,
        annotation.semanticLabel,
        annotation.colorToken,
        annotation.favorite,
        annotation.createdAt,
        annotation.updatedAt,
        annotation.revision,
        annotation.deletedAt,
      ],
    );
  }

  @override
  Future<void> remove(String id) {
    return _database.customStatement(
      'DELETE FROM annotations WHERE id = ?',
      <Object?>[id],
    );
  }

  Annotation _annotationFromRow(QueryRow row) {
    final Map<String, Object?> data = row.data;
    return Annotation(
      id: data['id']! as String,
      documentId: data['document_id']! as String,
      type: DatabaseSerialization.enumValue(
        AnnotationType.values,
        data['type'],
        AnnotationType.highlight,
      ),
      anchor: DatabaseSerialization.decodeAnchor(data['anchor_json']!),
      quote: data['quote'] as String?,
      note: data['note'] as String?,
      semanticLabel: data['semantic_label'] as String?,
      colorToken: data['color_token'] as String?,
      favorite: DatabaseSerialization.boolean(data['favorite']),
      createdAt: DatabaseSerialization.dateTime(data['created_at']),
      updatedAt: DatabaseSerialization.dateTime(data['updated_at']),
      revision: data['revision'] as int? ?? 1,
      deletedAt: DatabaseSerialization.nullableDateTime(data['deleted_at']),
    );
  }
}
