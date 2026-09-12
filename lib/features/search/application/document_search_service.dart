import 'dart:async';

import 'package:kola/document/graph/kola_document_graph.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/registry/format_registry.dart';
import 'package:kola/features/library/domain/document_repository.dart';
import 'package:kola/features/search/domain/search_models.dart';
import 'package:kola/features/search/domain/search_repository.dart';

final class DocumentSearchService {
  DocumentSearchService({
    required DocumentRepository documents,
    required SearchRepository search,
    required FormatRegistry formats,
  }) : this._(documents, search, formats);

  DocumentSearchService._(
    this._documents,
    this._search,
    this._formats,
  );

  static const String extractorVersion = 'kola-search-v1';

  final DocumentRepository _documents;
  final SearchRepository _search;
  final FormatRegistry _formats;
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  Future<void> ensureIndexed(KolaDocument document) {
    final Future<void>? active = _inFlight[document.id];
    if (active != null) return active;

    final Future<void> task = _indexIfNeeded(document);
    _inFlight[document.id] = task;
    return task.whenComplete(() {
      if (identical(_inFlight[document.id], task)) {
        _inFlight.remove(document.id);
      }
    });
  }

  Future<void> _indexIfNeeded(KolaDocument document) async {
    final SearchIndexStatus? status = await _search.getIndexStatus(document.id);
    if (status != null &&
        status.indexedRevision == document.revision &&
        status.extractorVersion == extractorVersion) {
      return;
    }

    final DocumentAdapter? adapter = _formats.adapterFor(document.format);
    if (adapter == null) {
      await _search.replaceDocumentIndex(
        document: document,
        extractorVersion: extractorVersion,
        chunks: const <IndexChunk>[],
      );
      return;
    }

    final DocumentHandle handle = await adapter.open(document);
    try {
      final List<IndexChunk> chunks = await adapter
          .extractIndexableContent(handle)
          .where((IndexChunk chunk) => chunk.text.trim().isNotEmpty)
          .toList();
      await _search.replaceDocumentIndex(
        document: document,
        extractorVersion: extractorVersion,
        chunks: chunks,
      );
    } finally {
      await handle.close();
    }
  }

  Future<List<SearchHit>> searchLibrary(
    String query, {
    int limit = 60,
  }) async {
    if (query.trim().isEmpty) return const <SearchHit>[];
    final List<KolaDocument> documents = await _documents.watchAll().first;
    for (final KolaDocument document in documents) {
      try {
        await ensureIndexed(document);
      } catch (_) {
        // A corrupt/missing document must not block results from the rest
        // of the local library. The document can be retried on the next query.
      }
    }
    return _search.search(query, limit: limit);
  }

  Future<List<SearchHit>> searchDocument(
    KolaDocument document,
    String query, {
    int limit = 80,
  }) async {
    if (query.trim().isEmpty) return const <SearchHit>[];
    await ensureIndexed(document);
    return _search.search(
      query,
      documentId: document.id,
      kind: SearchHitKind.content,
      limit: limit,
    );
  }
}
