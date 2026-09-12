import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/core/providers/search_providers.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/search/application/document_search_service.dart';
import 'package:kola/features/search/domain/search_models.dart';
import 'package:kola/features/search/presentation/search_snippet_text.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<SearchHit> _results = const <SearchHit>[];
  bool _loading = false;
  Object? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final String query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const <SearchHit>[];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_runSearch(query));
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DocumentSearchService service = ref.read(documentSearchServiceProvider);
      final List<SearchHit> hits = await service.searchLibrary(query);
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _results = hits;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _results = const <SearchHit>[];
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        const SliverAppBar.large(title: Text('Search')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            KolaSpacing.lg,
            0,
            KolaSpacing.lg,
            KolaSpacing.xxl,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              TextField(
                controller: _controller,
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search document text, titles, and authors',
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(KolaSpacing.sm),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: _onQueryChanged,
              ),
              const SizedBox(height: KolaSpacing.xl),
              if (_controller.text.trim().isEmpty)
                const _EmptySearch()
              else if (_error != null)
                _SearchError(error: _error!)
              else if (!_loading && _results.isEmpty)
                const _NoResults()
              else
                _SearchResults(
                  hits: _results,
                  onOpen: _openHit,
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openHit(SearchHit hit) {
    final DocumentLocation? target = hit.kind == SearchHitKind.content
        ? hit.location
        : null;
    context.push(
      '/reader/${Uri.encodeComponent(hit.documentId)}',
      extra: target,
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KolaSpacing.xxl),
          child: Column(
            children: <Widget>[
              Icon(Icons.manage_search_rounded, size: 52, color: scheme.primary),
              const SizedBox(height: KolaSpacing.md),
              Text(
                'Search stays on your device',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: KolaSpacing.xs),
              Text(
                'Kola builds a private local index when a document is searched for the first time. Later searches reuse that index.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.hits, required this.onOpen});

  final List<SearchHit> hits;
  final ValueChanged<SearchHit> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${hits.length} local ${hits.length == 1 ? 'result' : 'results'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: KolaSpacing.md),
        for (final SearchHit hit in hits)
          Padding(
            padding: const EdgeInsets.only(bottom: KolaSpacing.sm),
            child: Card(
              child: ListTile(
                isThreeLine: true,
                leading: Icon(
                  hit.kind == SearchHitKind.metadata
                      ? Icons.menu_book_rounded
                      : Icons.description_rounded,
                ),
                title: Text(hit.documentTitle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: KolaSpacing.xxs),
                    Text(
                      hit.kind == SearchHitKind.metadata
                          ? 'Document metadata'
                          : hit.sectionLabel ??
                                (hit.pageNumber == null
                                    ? 'Document text'
                                    : 'Page ${hit.pageNumber}'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: KolaSpacing.xxs),
                    SearchSnippetText(hit.snippet, maxLines: 2),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpen(hit),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: KolaSpacing.xxl),
      child: Center(child: Text('No local matches found.')),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolaSpacing.xxl),
      child: Center(
        child: Text(
          'Search failed locally.\n$error',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
