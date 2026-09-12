import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/library/presentation/import_document_button.dart';
import 'package:kola/features/progress/domain/reading_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<KolaDocument>> documents = ref.watch(documentsProvider);
    final AsyncValue<List<PlannedReadingItem>> readingList = ref.watch(
      readingListProvider,
    );
    final AsyncValue<List<ReadingSession>> sessions = ref.watch(
      allReadingSessionsProvider,
    );

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          pinned: false,
          title: const Text('Your reading space'),
          actions: const <Widget>[
            ImportDocumentButton(),
            SizedBox(width: KolaSpacing.xs),
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
              documents.when(
                data: (List<KolaDocument> items) => items.isEmpty
                    ? const _EmptyReadingCard()
                    : _ContinueReadingCard(document: items.first),
                loading: () => const _LoadingCard(height: 190),
                error: (_, _) => const _InlineError(
                  message: 'Your library could not be loaded.',
                ),
              ),
              const SizedBox(height: KolaSpacing.xl),
              const _SectionHeader(title: 'Next up'),
              const SizedBox(height: KolaSpacing.md),
              readingList.when(
                data: (List<PlannedReadingItem> items) =>
                    _NextUpRow(items: items),
                loading: () => const _LoadingCard(height: 156),
                error: (_, _) => const _InlineError(
                  message: 'Your reading list could not be loaded.',
                ),
              ),
              const SizedBox(height: KolaSpacing.xl),
              const _SectionHeader(title: 'This week'),
              const SizedBox(height: KolaSpacing.md),
              _InsightStrip(
                documentCount: documents.value?.length ?? 0,
                readingListCount: readingList.value?.length ?? 0,
                sessions: sessions.value ?? const <ReadingSession>[],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.document});

  final KolaDocument document;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String author = document.metadata.authors.isEmpty
        ? document.format.name.toUpperCase()
        : document.metadata.authors.join(', ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(KolaSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 104,
              height: 156,
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
                size: 42,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: KolaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    document.metadata.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: KolaSpacing.xs),
                  Text(
                    author,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: KolaSpacing.md),
                  Text(
                    document.lastOpenedAt == null
                        ? 'Ready to start'
                        : 'Continue where you left off',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: KolaSpacing.md),
                  FilledButton.icon(
                    onPressed: () => context.push('/reader/${Uri.encodeComponent(document.id)}'),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Open'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReadingCard extends StatelessWidget {
  const _EmptyReadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KolaSpacing.xl),
        child: Row(
          children: <Widget>[
            const Icon(Icons.library_add_rounded, size: 38),
            const SizedBox(width: KolaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Your library is empty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: KolaSpacing.xs),
                  const Text(
                    'Import a document to start building your reading space.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextUpRow extends StatelessWidget {
  const _NextUpRow({required this.items});

  final List<PlannedReadingItem> items;

  @override
  Widget build(BuildContext context) {
    final List<PlannedReadingItem> visible = items.take(6).toList(growable: false);
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: KolaSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index == visible.length) {
            return InkWell(
              borderRadius: KolaRadius.md,
              onTap: () {},
              child: Container(
                width: 124,
                decoration: BoxDecoration(
                  borderRadius: KolaRadius.md,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.add_rounded),
                    SizedBox(height: KolaSpacing.xs),
                    Text('Add to list'),
                  ],
                ),
              ),
            );
          }

          final PlannedReadingItem item = visible[index];
          return SizedBox(
            width: 152,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(KolaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.book_rounded),
                    const Spacer(),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: KolaSpacing.xs),
                    Text(
                      _readingListLabel(item.status),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _readingListLabel(ReadingListStatus status) => switch (status) {
    ReadingListStatus.wantToRead => 'Want to read',
    ReadingListStatus.nextUp => 'Next up',
    ReadingListStatus.reading => 'Reading',
    ReadingListStatus.paused => 'Paused',
    ReadingListStatus.completed => 'Completed',
    ReadingListStatus.abandoned => 'Not for me',
  };
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.documentCount,
    required this.readingListCount,
    required this.sessions,
  });

  final int documentCount;
  final int readingListCount;
  final List<ReadingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime weekStart = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: now.weekday - DateTime.monday),
    );
    final Duration activeTime = sessions
        .where(
          (ReadingSession session) => !session.startedAt.isBefore(weekStart),
        )
        .fold(
          Duration.zero,
          (Duration total, ReadingSession session) => total + session.activeTime,
        );

    final List<(IconData, String, String)> insights =
        <(IconData, String, String)>[
          (
            Icons.schedule_rounded,
            _formatDuration(activeTime),
            'Reading time',
          ),
          (Icons.local_library_rounded, '$documentCount', 'Documents'),
          (
            Icons.playlist_add_check_rounded,
            '$readingListCount',
            'Reading list',
          ),
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
                          Text(
                            insight.$2,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            insight.$3,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Card(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KolaSpacing.lg),
        child: Text(message),
      ),
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onPressed, child: Text(action!)),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  if (duration.inMinutes < 60) return '${duration.inMinutes}m';
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}
