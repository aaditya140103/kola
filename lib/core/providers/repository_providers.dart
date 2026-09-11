import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/database/database_provider.dart';
import 'package:kola/features/annotations/data/drift_annotation_repository.dart';
import 'package:kola/features/annotations/domain/annotation_repository.dart';
import 'package:kola/features/library/data/drift_document_repository.dart';
import 'package:kola/features/library/domain/document_repository.dart';
import 'package:kola/features/progress/data/drift_reading_repository.dart';
import 'package:kola/features/progress/domain/reading_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DriftDocumentRepository(ref.watch(kolaDatabaseProvider));
});

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return DriftReadingRepository(ref.watch(kolaDatabaseProvider));
});

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return DriftAnnotationRepository(ref.watch(kolaDatabaseProvider));
});
