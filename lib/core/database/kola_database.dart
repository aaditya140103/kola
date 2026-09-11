import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'kola_database.g.dart';

@DriftDatabase(include: <String>{'schema.drift'})
final class KolaDatabase extends _$KolaDatabase {
  KolaDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'kola'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) => migrator.createAll(),
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
