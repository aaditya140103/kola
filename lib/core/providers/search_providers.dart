import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/document_engine_providers.dart';
import 'package:kola/core/providers/repository_providers.dart';
import 'package:kola/features/search/application/document_search_service.dart';

final documentSearchServiceProvider = Provider<DocumentSearchService>((ref) {
  return DocumentSearchService(
    documents: ref.watch(documentRepositoryProvider),
    search: ref.watch(searchRepositoryProvider),
    formats: ref.watch(formatRegistryProvider),
  );
});
