import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/core/database/kola_database.dart';

void main() {
  late KolaDatabase database;

  setUp(() {
    database = KolaDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('stores document and reading state with foreign keys enabled', () async {
    final String now = DateTime.utc(2026, 9, 12).toIso8601String();

    await database.customStatement(
      '''
      INSERT INTO documents (
        id, source_kind, source_uri, format, title,
        imported_at, revision, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        'doc-1',
        'linkedFile',
        'file:///tmp/book.epub',
        'epub',
        'Example Book',
        now,
        1,
        now,
      ],
    );

    await database.customStatement(
      '''
      INSERT INTO reading_states (
        document_id, position_progress, view_mode, zoom, updated_at
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      <Object?>['doc-1', 0.42, 'flow', 1.0, now],
    );

    final rows = await database
        .customSelect(
          'SELECT title FROM documents WHERE id = ?',
          variables: <Variable<Object>>[Variable.withString('doc-1')],
        )
        .get();

    expect(rows.single.read<String>('title'), 'Example Book');
  });

  test('deleting a document cascades its reading state', () async {
    final String now = DateTime.utc(2026, 9, 12).toIso8601String();

    await database.customStatement(
      '''
      INSERT INTO documents (
        id, source_kind, source_uri, format, title,
        imported_at, revision, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        'doc-2',
        'managedCopy',
        'file:///library/book.pdf',
        'pdf',
        'Cascade Test',
        now,
        1,
        now,
      ],
    );

    await database.customStatement(
      '''
      INSERT INTO reading_states (
        document_id, position_progress, view_mode, zoom, updated_at
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      <Object?>['doc-2', 0.1, 'fidelity', 1.0, now],
    );

    await database.customStatement(
      'DELETE FROM documents WHERE id = ?',
      <Object?>['doc-2'],
    );

    final rows = await database
        .customSelect(
          'SELECT document_id FROM reading_states WHERE document_id = ?',
          variables: <Variable<Object>>[Variable.withString('doc-2')],
        )
        .get();

    expect(rows, isEmpty);
  });
}
