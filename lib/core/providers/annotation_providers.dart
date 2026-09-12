import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/core/providers/document_engine_providers.dart';
import 'package:kola/core/providers/repository_providers.dart';
import 'package:kola/features/annotations/application/annotation_creation_service.dart';
import 'package:kola/features/annotations/application/annotation_geometry_recovery_service.dart';
import 'package:kola/features/annotations/application/annotation_management_service.dart';
import 'package:kola/features/annotations/application/annotation_navigation_service.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';

final annotationCreationServiceProvider = Provider<AnnotationCreationService>((ref) {
  return AnnotationCreationService(ref.watch(annotationRepositoryProvider));
});

final annotationManagementServiceProvider = Provider<AnnotationManagementService>((ref) {
  return AnnotationManagementService(ref.watch(annotationRepositoryProvider));
});

final annotationNavigationServiceProvider = Provider<AnnotationNavigationService>((ref) {
  return AnnotationNavigationService(ref.watch(formatRegistryProvider));
});

final annotationGeometryRecoveryServiceProvider =
    Provider<AnnotationGeometryRecoveryService>((ref) {
      return AnnotationGeometryRecoveryService(ref.watch(formatRegistryProvider));
    });

final recoveredAnnotationGeometryProvider = FutureProvider.family<
  Map<String, List<Map<String, Object?>>>,
  String
>((ref, documentId) async {
  final document = await ref.watch(documentProvider(documentId).future);
  if (document == null) {
    return const <String, List<Map<String, Object?>>>{};
  }
  final List<Annotation> annotations = await ref.watch(
    annotationsProvider(documentId).future,
  );
  return ref
      .watch(annotationGeometryRecoveryServiceProvider)
      .recover(document, annotations);
});
