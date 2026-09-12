import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/library/presentation/import_document_button.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<KolaDocument>> documents = ref.watch(documentsProvider);

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          title: const Text('Library'),
          actions: <Widget>[
            IconButton(
              onPressed: () {},
              tooltip: 'Filter',
              icon: const Icon(Icons.tune_rounded),
            ),
            const ImportDocumentButton(tooltip: 'Import'),
            const SizedBox(width: KolaSpacing.xs),
          ],
        ),
        documents.when(
          data: (List<KolaDocument> items) => items.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyLibrary(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    KolaSpacing.lg,
                    0,
                    KolaSpacing.lg,
                    KolaSpacing.xxl,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (BuildContext context, SliverConstraints constraints) {
                      final double width = constraints.crossAxisExtent;
                      final int columns = switch (width) {
                        < 520 => 2,
                        < 820 => 3,
                        < 1120 => 4,
                        _ => 5,
                      };

                      return SliverGrid.builder(
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: KolaSpacing.lg,
                          crossAxisSpacing: KolaSpacing.md,
                          childAspectRatio: 0.66,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          return _BookTile(document: items[index]);
                        },
                      );
                    },
                  ),
                ),
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Your library could not be loaded.')),
          ),
        ),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.document});

  final KolaDocument document;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String author = document.metadata.authors.isEmpty
        ? document.format.name.toUpperCase()
        : document.metadata.authors.join(', ');

    return InkWell(
      borderRadius: KolaRadius.md,
      onTap: () => context.push('/reader/${Uri.encodeComponent(document.id)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Hero(
              tag: 'cover-${document.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: KolaRadius.md,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      scheme.primaryContainer,
                      scheme.surfaceContainerHighest,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 42,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: KolaSpacing.sm),
          Text(
            document.metadata.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: KolaSpacing.xxs),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: KolaSpacing.xs),
          Text(
            document.lastOpenedAt == null ? 'Not started' : 'Recently opened',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KolaSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.local_library_outlined,
                size: 58,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: KolaSpacing.md),
              Text(
                'No documents yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: KolaSpacing.sm),
              const Text(
                'Import a local document and it will appear here. Kola keeps your library available offline.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
