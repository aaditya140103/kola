import 'package:kola/document/model/document_models.dart';

enum SearchHitKind { metadata, content }

final class SearchHit {
  const SearchHit({
    required this.documentId,
    required this.documentTitle,
    required this.location,
    required this.snippet,
    required this.kind,
    required this.rank,
    this.sectionLabel,
  });

  final String documentId;
  final String documentTitle;
  final DocumentLocation location;
  final String snippet;
  final SearchHitKind kind;
  final double rank;
  final String? sectionLabel;

  int? get pageNumber {
    if (location.scheme != 'pdf') return null;
    final Object? raw = location.data['page'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }
}

final class SearchIndexStatus {
  const SearchIndexStatus({
    required this.documentId,
    required this.indexedRevision,
    required this.extractorVersion,
    required this.indexedAt,
  });

  final String documentId;
  final int indexedRevision;
  final String extractorVersion;
  final DateTime indexedAt;
}
