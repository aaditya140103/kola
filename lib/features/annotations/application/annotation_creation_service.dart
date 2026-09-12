import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/text/document_text_selection.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/annotations/domain/annotation_repository.dart';
import 'package:uuid/uuid.dart';

typedef AnnotationIdGenerator = String Function();
typedef AnnotationClock = DateTime Function();

final class AnnotationCreationService {
  AnnotationCreationService(
    this._repository, {
    AnnotationIdGenerator? idGenerator,
    AnnotationClock? clock,
  }) : _idGenerator = idGenerator ?? const Uuid().v4,
       _clock = clock ?? _utcNow;

  final AnnotationRepository _repository;
  final AnnotationIdGenerator _idGenerator;
  final AnnotationClock _clock;

  Future<Annotation> createHighlight({
    required KolaDocument document,
    required DocumentTextSelection selection,
    String colorToken = 'highlight.yellow',
    String semanticLabel = 'important',
  }) async {
    if (selection.documentId != document.id) {
      throw ArgumentError.value(
        selection.documentId,
        'selection.documentId',
        'Selection belongs to a different document.',
      );
    }
    if (selection.isEmpty) {
      throw ArgumentError.value(selection.text, 'selection', 'Selection is empty.');
    }

    final DocumentTextSelectionRange first = selection.ranges.first;
    final DocumentTextSelectionRange last = selection.ranges.last;
    final int? firstPage = first.pageNumber;
    final int? lastPage = last.pageNumber;
    final bool singleLogicalRange =
        firstPage != null && firstPage == lastPage && selection.ranges.length == 1;

    final List<Map<String, Object?>> sourceGeometry = <Map<String, Object?>>[];
    final List<Map<String, Object?>> fallbackRanges = <Map<String, Object?>>[];
    for (final DocumentTextSelectionRange range in selection.ranges) {
      final int? page = range.pageNumber;
      fallbackRanges.add(<String, Object?>{
        'scheme': range.location.scheme,
        'page': page,
        'start': range.start,
        'end': range.end,
      });
      for (final rect in range.rects) {
        sourceGeometry.add(<String, Object?>{
          'scheme': range.location.scheme,
          'coordinateSpace': 'pdfPagePoints',
          'page': page,
          'start': range.start,
          'end': range.end,
          'left': rect.left,
          'top': rect.top,
          'right': rect.right,
          'bottom': rect.bottom,
        });
      }
    }

    final Map<String, Object?> locatorData = <String, Object?>{
      'page': firstPage,
      'start': first.start,
      'end': singleLogicalRange ? first.end : last.end,
    };
    if (lastPage != null && lastPage != firstPage) {
      locatorData['endPage'] = lastPage;
    }

    final DateTime now = _clock().toUtc();
    final Annotation annotation = Annotation(
      id: _idGenerator(),
      documentId: document.id,
      type: AnnotationType.highlight,
      anchor: AnnotationAnchor(
        documentId: document.id,
        sourceLocator: DocumentLocation(
          scheme: first.location.scheme,
          data: locatorData,
          label: firstPage == lastPage
              ? first.location.label
              : 'Pages $firstPage–$lastPage',
        ),
        exactQuote: selection.text,
        prefixContext: first.prefixContext,
        suffixContext: last.suffixContext,
        logicalStart: singleLogicalRange ? first.start : null,
        logicalEnd: singleLogicalRange ? first.end : null,
        sourceGeometry: sourceGeometry,
        formatSpecificFallback: <String, Object?>{
          'ranges': fallbackRanges,
        },
      ),
      quote: selection.text,
      semanticLabel: semanticLabel,
      colorToken: colorToken,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.upsert(annotation);
    return annotation;
  }

  static DateTime _utcNow() => DateTime.now().toUtc();
}
