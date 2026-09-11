import 'package:kola/features/annotations/domain/annotation_models.dart';

abstract interface class AnnotationRepository {
  Stream<List<Annotation>> watchForDocument(String documentId);

  Future<Annotation?> getById(String id);

  Future<void> upsert(Annotation annotation);

  Future<void> remove(String id);
}
