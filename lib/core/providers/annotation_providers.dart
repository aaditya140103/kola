import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/repository_providers.dart';
import 'package:kola/features/annotations/application/annotation_creation_service.dart';

final annotationCreationServiceProvider = Provider<AnnotationCreationService>((ref) {
  return AnnotationCreationService(ref.watch(annotationRepositoryProvider));
});
