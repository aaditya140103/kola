import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/annotations/domain/annotation_repository.dart';

typedef AnnotationUpdateClock = DateTime Function();

final class AnnotationManagementService {
  AnnotationManagementService(
    this._repository, {
    AnnotationUpdateClock? clock,
  }) : _clock = clock ?? _utcNow;

  final AnnotationRepository _repository;
  final AnnotationUpdateClock _clock;

  Future<Annotation> setHighlightColor(
    Annotation annotation,
    String colorToken,
  ) {
    final DateTime now = _clock().toUtc();
    if (annotation.type != AnnotationType.highlight) {
      throw ArgumentError.value(
        annotation.type,
        'annotation.type',
        'Only highlight annotations can be recolored.',
      );
    }
    return _persist(
      annotation,
      now: now,
      colorToken: colorToken,
      note: annotation.note,
      deletedAt: annotation.deletedAt,
    );
  }

  Future<Annotation> setNote(Annotation annotation, String? note) {
    final DateTime now = _clock().toUtc();
    final String? normalized = note?.trim();
    return _persist(
      annotation,
      now: now,
      colorToken: annotation.colorToken,
      note: normalized == null || normalized.isEmpty ? null : normalized,
      deletedAt: annotation.deletedAt,
    );
  }

  Future<Annotation> delete(Annotation annotation) {
    final DateTime now = _clock().toUtc();
    return _persist(
      annotation,
      now: now,
      colorToken: annotation.colorToken,
      note: annotation.note,
      deletedAt: now,
    );
  }

  Future<Annotation> _persist(
    Annotation annotation, {
    required DateTime now,
    required String? colorToken,
    required String? note,
    required DateTime? deletedAt,
  }) async {
    final Annotation updated = Annotation(
      id: annotation.id,
      documentId: annotation.documentId,
      type: annotation.type,
      anchor: annotation.anchor,
      quote: annotation.quote,
      note: note,
      semanticLabel: annotation.semanticLabel,
      colorToken: colorToken,
      favorite: annotation.favorite,
      createdAt: annotation.createdAt,
      updatedAt: now,
      revision: annotation.revision + 1,
      deletedAt: deletedAt,
    );
    await _repository.upsert(updated);
    return updated;
  }

  static DateTime _utcNow() => DateTime.now().toUtc();
}
