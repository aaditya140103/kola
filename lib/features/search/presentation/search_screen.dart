import 'package:flutter/material.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search your library, annotations, and notes',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: KolaSpacing.xl),
              if (_controller.text.trim().isEmpty)
                const _EmptySearch()
              else
                _DemoSearchResults(query: _controller.text.trim()),
            ],
          ),
        ),
      ],
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KolaSpacing.xxl),
          child: Column(
            children: <Widget>[
              Icon(Icons.manage_search_rounded, size: 52, color: scheme.primary),
              const SizedBox(height: KolaSpacing.md),
              Text('Search stays on your device', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: KolaSpacing.xs),
              Text(
                'Kola will index document text, OCR text, annotations, notes, titles, and metadata locally.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoSearchResults extends StatelessWidget {
  const _DemoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Prototype results for “$query”', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: KolaSpacing.md),
        for (final String title in <String>[
          'The Design of Everyday Things',
          'System Design Notes',
          'GPU Architecture Notes',
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_rounded),
              title: Text(title),
              subtitle: Text('Local full-text search integration comes after the document graph foundation.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ),
      ],
    );
  }
}
