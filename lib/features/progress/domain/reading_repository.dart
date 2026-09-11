import 'package:kola/features/progress/domain/reading_models.dart';

abstract interface class ReadingRepository {
  Stream<ReadingState?> watchState(String documentId);

  Future<void> saveState(ReadingState state);

  Stream<ReadingCoverage?> watchCoverage(String documentId);

  Future<void> saveCoverage(ReadingCoverage coverage);

  Stream<List<ReadingSession>> watchSessions(String documentId);

  Future<void> saveSession(ReadingSession session);

  Stream<List<PlannedReadingItem>> watchReadingList();

  Future<void> savePlannedItem(PlannedReadingItem item);

  Future<void> removePlannedItem(String id);

  Stream<List<ReadingGoal>> watchGoals();

  Future<void> saveGoal(ReadingGoal goal);
}
