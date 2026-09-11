import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/repository_providers.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/progress/domain/reading_models.dart';

final documentsProvider = StreamProvider<List<KolaDocument>>((ref) {
  return ref.watch(documentRepositoryProvider).watchAll();
});

final documentProvider = FutureProvider.family<KolaDocument?, String>((
  ref,
  documentId,
) {
  return ref.watch(documentRepositoryProvider).getById(documentId);
});

final readingListProvider = StreamProvider<List<PlannedReadingItem>>((ref) {
  return ref.watch(readingRepositoryProvider).watchReadingList();
});

final readingGoalsProvider = StreamProvider<List<ReadingGoal>>((ref) {
  return ref.watch(readingRepositoryProvider).watchGoals();
});

final allReadingSessionsProvider = StreamProvider<List<ReadingSession>>((ref) {
  return ref.watch(readingRepositoryProvider).watchAllSessions();
});

final readingStateProvider = StreamProvider.family<ReadingState?, String>((
  ref,
  documentId,
) {
  return ref.watch(readingRepositoryProvider).watchState(documentId);
});

final readingCoverageProvider = StreamProvider.family<ReadingCoverage?, String>((
  ref,
  documentId,
) {
  return ref.watch(readingRepositoryProvider).watchCoverage(documentId);
});

final readingSessionsProvider = StreamProvider.family<List<ReadingSession>, String>((
  ref,
  documentId,
) {
  return ref.watch(readingRepositoryProvider).watchSessions(documentId);
});

final annotationsProvider = StreamProvider.family<List<Annotation>, String>((
  ref,
  documentId,
) {
  return ref.watch(annotationRepositoryProvider).watchForDocument(documentId);
});
