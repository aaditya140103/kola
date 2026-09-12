import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/search/domain/search_models.dart';

abstract interface class SearchRepository {
  Future<SearchIndexStatus?> getIndexStatus(String documentId);

  Future<void> replaceDocumentIndex({
    required KolaDocument document,
    required String extractorVersion,
    required List<IndexChunk> chunks,
  });

  Future<void> deleteDocumentIndex(String documentId);

  Future<List<SearchHit>> search(
    String query, {
    String? documentId,
    SearchHitKind? kind,
    int limit = 50,
  });
}
