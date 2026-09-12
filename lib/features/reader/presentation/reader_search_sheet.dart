import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/search_providers.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/search/application/document_search_service.dart';
import 'package:kola/features/search/domain/search_models.dart';
import 'package:kola/features/search/presentation/search_snippet_text.dart';

class ReaderSearchSheet extends ConsumerStatefulWidget {
  const ReaderSearchSheet({required this.document, super.key});

  final KolaDocument document;

  @override
  ConsumerState<ReaderSearchSheet> createState() => _ReaderSearchSheetState();
}

class _ReaderSearchSheetState extends ConsumerState<ReaderSearchSheet> {
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
    _debounce = Timer(const Duration(milliseconds: 250), () {
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
      final List<SearchHit> hits = await service.searchDocument(
        widget.document,
        query,
      );
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KolaSpacing.lg,
              KolaSpacing.xs,
              KolaSpacing.lg,
              KolaSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Search in ${widget.document.metadata.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: KolaSpacing.md),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Find words or phrases',
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
                ),
                const SizedBox(height: KolaSpacing.md),
                Expanded(
                  child: _error != null
                      ? Center(
                          child: Text(
                            'Kola could not index this document.\n$_error',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.error),
                          ),
                        )
                      : _controller.text.trim().isEmpty
                      ? const Center(
                          child: Text(
                            'Search is local. The document is indexed on this device when needed.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : !_loading && _results.isEmpty
                      ? const Center(child: Text('No matches found.'))
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final SearchHit hit = _results[index];
                            final int? page = hit.pageNumber;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(page?.toString() ?? '•'),
                              ),
                              title: Text(
                                hit.sectionLabel ??
                                    (page == null ? 'Match' : 'Page $page'),
                              ),
                              subtitle: SearchSnippetText(hit.snippet),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.of(context).pop(hit),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
