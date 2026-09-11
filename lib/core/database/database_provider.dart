import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/database/kola_database.dart';

final kolaDatabaseProvider = Provider<KolaDatabase>((Ref ref) {
  final KolaDatabase database = KolaDatabase();
  ref.onDispose(database.close);
  return database;
});
