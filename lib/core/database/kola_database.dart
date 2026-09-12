import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'kola_database.g.dart';

@DriftDatabase(include: <String>{'schema.drift'})
final class KolaDatabase extends _$KolaDatabase {
  KolaDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'kola'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
      await _ensureSearchSchema();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await _ensureSearchSchema();
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureSearchSchema();
    },
  );

  Future<void> _ensureSearchSchema() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS document_search_state (
        document_id TEXT NOT NULL PRIMARY KEY
          REFERENCES documents(id) ON DELETE CASCADE,
        indexed_revision INTEGER NOT NULL,
        extractor_version TEXT NOT NULL,
        indexed_at TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS document_search USING fts5(
        document_id UNINDEXED,
        locator_json UNINDEXED,
        section_label UNINDEXED,
        kind UNINDEXED,
        body,
        tokenize = 'unicode61 remove_diacritics 2'
      )
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS documents_search_cleanup
      AFTER DELETE ON documents
      BEGIN
        DELETE FROM document_search WHERE document_id = old.id;
        DELETE FROM document_search_state WHERE document_id = old.id;
      END
    ''');
  }
}
