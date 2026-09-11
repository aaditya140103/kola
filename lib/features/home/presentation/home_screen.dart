import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          pinned: false,
          title: const Text('Your reading space'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Import document',
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: KolaSpacing.xs),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            KolaSpacing.lg,
            KolaSpacing.sm,
            KolaSpacing.lg,
            KolaSpacing.xxl,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              _SectionHeader(
                title: 'Continue reading',
                action: 'View library',
                onPressed: () => context.go('/library'),
              ),
              const SizedBox(height: KolaSpacing.md),
              _ContinueReadingCard(theme: theme),
              const SizedBox(height: KolaSpacing.xl),
              const _SectionHeader(title: 'Next up'),
              const SizedBox(height: KolaSpacing.md),
              const _NextUpRow(),
              const SizedBox(height: KolaSpacing.xl),
              const _SectionHeader(title: 'This week'),
              const SizedBox(height: KolaSpacing.md),
              const _InsightStrip(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 720;
        final Widget cover = Container(
          width: compact ? 104 : 132,
          height: compact ? 170 : 206,
          decoration: BoxDecoration(
            borderRadius: KolaRadius.md,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                scheme.primaryContainer,
                scheme.tertiaryContainer,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.auto_stories_rounded,
            size: compact ? 42 : 52,
            color: scheme.onPrimaryContainer,
          ),
        );

        final Widget details = Expanded(
          child: Padding(
            padding: EdgeInsets.all(compact ? KolaSpacing.md : KolaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'The Design of Everyday Things',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: KolaSpacing.xs),
                Text('Don Norman', style: theme.textTheme.bodyLarge),
                const SizedBox(height: KolaSpacing.md),
                ClipRRect(
                  borderRadius: KolaRadius.pill,
                  child: const LinearProgressIndicator(value: 0.68, minHeight: 7),
                ),
                const SizedBox(height: KolaSpacing.sm),
                Wrap(
                  spacing: KolaSpacing.md,
                  runSpacing: KolaSpacing.xs,
                  children: <Widget>[
                    Text('68% position', style: theme.textTheme.labelLarge),
                    Text('61% read', style: theme.textTheme.labelLarge),
                    Text('5h 24m', style: theme.textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: KolaSpacing.md),
                FilledButton.icon(
                  onPressed: () => context.go('/reader/demo'),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ),
        );

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(KolaSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[cover, details],
            ),
          ),
        );
      },
    );
  }
}

class _NextUpRow extends StatelessWidget {
  const _NextUpRow();

  @override
  Widget build(BuildContext context) {
    const List<(String, double)> items = <(String, double)>[
      ('Deep Work', 0.18),
      ('Rust for Rustaceans', 0.42),
      ('Designing Data-Intensive Applications', 0.07),
    ];

    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: KolaSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index == items.length) {
            return InkWell(
              borderRadius: KolaRadius.md,
              onTap: () {},
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: KolaRadius.md,
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.add_rounded),
                    SizedBox(height: KolaSpacing.xs),
                    Text('Add book'),
                  ],
                ),
              ),
            );
          }

          final (String title, double progress) = items[index];
          return SizedBox(
            width: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: KolaRadius.md,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Center(child: Icon(Icons.book_rounded, size: 38)),
                  ),
                ),
                const SizedBox(height: KolaSpacing.xs),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: KolaSpacing.xxs),
                LinearProgressIndicator(value: progress, minHeight: 3),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip();

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String, String)> insights = <(IconData, String, String)>[
      (Icons.schedule_rounded, '4h 18m', 'Reading time'),
      (Icons.local_library_rounded, '5', 'Documents'),
      (Icons.edit_rounded, '12', 'Annotations'),
    ];

    return Wrap(
      spacing: KolaSpacing.sm,
      runSpacing: KolaSpacing.sm,
      children: insights
          .map(
            ((IconData, String, String) insight) => SizedBox(
              width: 180,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(KolaSpacing.md),
                  child: Row(
                    children: <Widget>[
                      Icon(insight.$1),
                      const SizedBox(width: KolaSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(insight.$2, style: Theme.of(context).textTheme.titleMedium),
                          Text(insight.$3, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onPressed});

  final String title;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onPressed, child: Text(action!)),
      ],
    );
  }
}
