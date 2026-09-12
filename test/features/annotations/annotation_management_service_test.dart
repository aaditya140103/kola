import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/features/annotations/application/annotation_management_service.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/annotations/domain/annotation_repository.dart';

void main() {
  final DateTime createdAt = DateTime.utc(2026, 9, 12, 10);
  final DateTime updatedAt = DateTime.utc(2026, 9, 12, 11);

  Annotation baseAnnotation() => Annotation(
    id: 'annotation-1',
    documentId: 'doc-1',
    type: AnnotationType.highlight,
    anchor: AnnotationAnchor(
      documentId: 'doc-1',
      sourceLocator: DocumentLocation(
        scheme: 'pdf',
        data: const <String, Object?>{'page': 8, 'start': 12, 'end': 20},
        label: 'Page 8',
      ),
      exactQuote: 'selected',
      sourceGeometry: const <Map<String, Object?>>[
        <String, Object?>{
          'scheme': 'pdf',
          'page': 8,
          'left': 10.0,
          'top': 20.0,
          'right': 40.0,
          'bottom': 12.0,
        },
      ],
    ),
    quote: 'selected',
    colorToken: 'highlight.yellow',
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  test('recolor preserves source anchor and increments revision', () async {
    final _MemoryAnnotationRepository repository = _MemoryAnnotationRepository();
    final AnnotationManagementService service = AnnotationManagementService(
      repository,
      clock: () => updatedAt,
    );

    final Annotation original = baseAnnotation();
    final Annotation changed = await service.setHighlightColor(
      original,
      'highlight.blue',
    );

    expect(changed.colorToken, 'highlight.blue');
    expect(changed.anchor, same(original.anchor));
    expect(changed.revision, 2);
    expect(changed.updatedAt, updatedAt);
    expect(repository.last, same(changed));
  });

  test('note edit preserves quote and source identity', () async {
    final _MemoryAnnotationRepository repository = _MemoryAnnotationRepository();
    final AnnotationManagementService service = AnnotationManagementService(
      repository,
      clock: () => updatedAt,
    );

    final Annotation original = baseAnnotation();
    final Annotation changed = await service.setNote(
      original,
      '  Useful idea  ',
    );

    expect(changed.note, 'Useful idea');
    expect(changed.quote, original.quote);
    expect(changed.anchor.sourceLocator?.data['page'], 8);
    expect(changed.createdAt, createdAt);
    expect(changed.revision, 2);
  });

  test('delete writes a tombstone instead of destroying source data', () async {
    final _MemoryAnnotationRepository repository = _MemoryAnnotationRepository();
    final AnnotationManagementService service = AnnotationManagementService(
      repository,
      clock: () => updatedAt,
    );

    final Annotation original = baseAnnotation();
    final Annotation changed = await service.delete(original);

    expect(changed.deletedAt, updatedAt);
    expect(changed.anchor, same(original.anchor));
    expect(changed.quote, original.quote);
    expect(changed.revision, 2);
    expect(repository.last, same(changed));
  });
}

final class _MemoryAnnotationRepository implements AnnotationRepository {
  Annotation? last;

  @override
  Future<Annotation?> getById(String id) async => last?.id == id ? last : null;

  @override
  Future<void> remove(String id) async {
    if (last?.id == id) last = null;
  }

  @override
  Future<void> upsert(Annotation annotation) async {
    last = annotation;
  }

  @override
  Stream<List<Annotation>> watchForDocument(String documentId) =>
      Stream<List<Annotation>>.value(
        last?.documentId == documentId && last?.deletedAt == null
            ? <Annotation>[last!]
            : const <Annotation>[],
      );
}
