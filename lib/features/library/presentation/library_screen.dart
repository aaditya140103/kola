import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          title: const Text('Library'),
          actions: <Widget>[
            IconButton(onPressed: () {}, tooltip: 'Filter', icon: const Icon(Icons.tune_rounded)),
            IconButton(onPressed: () {}, tooltip: 'Import', icon: const Icon(Icons.add_rounded)),
            const SizedBox(width: KolaSpacing.xs),
          ],
        ),
        SliverPadding(
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
                itemCount: _demoBooks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: KolaSpacing.lg,
                  crossAxisSpacing: KolaSpacing.md,
                  childAspectRatio: 0.64,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _BookTile(book: _demoBooks[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});

  final _DemoBook book;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: KolaRadius.md,
      onTap: () => context.go('/reader/${book.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Hero(
              tag: 'cover-${book.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: KolaRadius.md,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[book.color, scheme.surfaceContainerHighest],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.auto_stories_rounded, size: 42, color: scheme.onSurface),
              ),
            ),
          ),
          const SizedBox(height: KolaSpacing.sm),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: KolaSpacing.xxs),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: KolaSpacing.xs),
          ClipRRect(
            borderRadius: KolaRadius.pill,
            child: LinearProgressIndicator(value: book.progress, minHeight: 4),
          ),
        ],
      ),
    );
  }
}

class _DemoBook {
  const _DemoBook(this.id, this.title, this.author, this.progress, this.color);

  final String id;
  final String title;
  final String author;
  final double progress;
  final Color color;
}

const List<_DemoBook> _demoBooks = <_DemoBook>[
  _DemoBook('design', 'The Design of Everyday Things', 'Don Norman', 0.68, Color(0xFF64D8C1)),
  _DemoBook('deep-work', 'Deep Work', 'Cal Newport', 0.42, Color(0xFF8EA7FF)),
  _DemoBook('ddia', 'Designing Data-Intensive Applications', 'Martin Kleppmann', 0.17, Color(0xFFF4B780)),
  _DemoBook('rust', 'Rust for Rustaceans', 'Jon Gjengset', 0.31, Color(0xFFD8906D)),
  _DemoBook('gpu', 'GPU Architecture Notes', 'Kola Library', 0.54, Color(0xFFB29AF1)),
  _DemoBook('systems', 'System Design Notes', 'Kola Library', 0.76, Color(0xFF83C98F)),
];
