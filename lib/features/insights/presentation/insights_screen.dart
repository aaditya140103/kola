import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/progress/domain/reading_models.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ReadingSession>> sessions = ref.watch(
      allReadingSessionsProvider,
    );
    final AsyncValue<List<KolaDocument>> documents = ref.watch(documentsProvider);
    final AsyncValue<List<PlannedReadingItem>> readingList = ref.watch(
      readingListProvider,
    );

    return CustomScrollView(
      slivers: <Widget>[
        const SliverAppBar.large(title: Text('Reading insights')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            KolaSpacing.lg,
            0,
            KolaSpacing.lg,
            KolaSpacing.xxl,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              sessions.when(
                data: (List<ReadingSession> items) => _InsightsBody(
                  sessions: items,
                  documents: documents.value ?? const <KolaDocument>[],
                  readingListCount: readingList.value?.length ?? 0,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(KolaSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(KolaSpacing.xl),
                    child: Text('Reading insights could not be loaded.'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({
    required this.sessions,
    required this.documents,
    required this.readingListCount,
  });

  final List<ReadingSession> sessions;
  final List<KolaDocument> documents;
  final int readingListCount;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = today.subtract(
      Duration(days: now.weekday - DateTime.monday),
    );
    final Duration todayTime = _sumActiveTime(
      sessions.where((ReadingSession session) => !session.startedAt.isBefore(today)),
    );
    final Duration weekTime = _sumActiveTime(
      sessions.where((ReadingSession session) => !session.startedAt.isBefore(weekStart)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MetricGrid(
          todayTime: todayTime,
          weekTime: weekTime,
          sessionCount: sessions.length,
          readingListCount: readingListCount,
        ),
        const SizedBox(height: KolaSpacing.xl),
        Text('Last 7 days', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: KolaSpacing.md),
        _WeekChart(sessions: sessions),
        const SizedBox(height: KolaSpacing.xl),
        Text('Most read', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: KolaSpacing.md),
        _MostReadList(sessions: sessions, documents: documents),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.todayTime,
    required this.weekTime,
    required this.sessionCount,
    required this.readingListCount,
  });

  final Duration todayTime;
  final Duration weekTime;
  final int sessionCount;
  final int readingListCount;

  @override
  Widget build(BuildContext context) {
    final List<(String, String, IconData)> metrics = <(String, String, IconData)>[
      ('Today', _formatDuration(todayTime), Icons.today_rounded),
      ('This week', _formatDuration(weekTime), Icons.date_range_rounded),
      ('Sessions', '$sessionCount', Icons.timer_outlined),
      ('Reading list', '$readingListCount', Icons.playlist_add_check_rounded),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth < 560 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: KolaSpacing.sm,
            crossAxisSpacing: KolaSpacing.sm,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (BuildContext context, int index) {
            final (String label, String value, IconData icon) = metrics[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(KolaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Icon(icon),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(value, style: Theme.of(context).textTheme.headlineSmall),
                        Text(label, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.sessions});

  final List<ReadingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<Duration> totals = List<Duration>.generate(7, (int index) {
      final DateTime day = today.subtract(Duration(days: 6 - index));
      final DateTime nextDay = day.add(const Duration(days: 1));
      return _sumActiveTime(
        sessions.where(
          (ReadingSession session) =>
              !session.startedAt.isBefore(day) && session.startedAt.isBefore(nextDay),
        ),
      );
    });
    final int maxMinutes = totals.fold<int>(
      0,
      (int maxValue, Duration duration) =>
          duration.inMinutes > maxValue ? duration.inMinutes : maxValue,
    );
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(KolaSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(7, (int index) {
              final DateTime day = today.subtract(Duration(days: 6 - index));
              final double fraction = maxMinutes == 0
                  ? 0.04
                  : (totals[index].inMinutes / maxMinutes).clamp(0.04, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KolaSpacing.xs),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: fraction,
                            child: Container(
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: KolaRadius.pill,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: KolaSpacing.xs),
                      Text(_weekdayLabel(day.weekday), style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MostReadList extends StatelessWidget {
  const _MostReadList({required this.sessions, required this.documents});

  final List<ReadingSession> sessions;
  final List<KolaDocument> documents;

  @override
  Widget build(BuildContext context) {
    final Map<String, Duration> totals = <String, Duration>{};
    for (final ReadingSession session in sessions) {
      totals.update(
        session.documentId,
        (Duration current) => current + session.activeTime,
        ifAbsent: () => session.activeTime,
      );
    }

    final List<MapEntry<String, Duration>> ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final Map<String, KolaDocument> byId = <String, KolaDocument>{
      for (final KolaDocument document in documents) document.id: document,
    };
    final List<MapEntry<String, Duration>> visible = ranked.take(5).toList(growable: false);

    if (visible.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(KolaSpacing.xl),
          child: Text('Start reading and your most-read documents will appear here.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: List<Widget>.generate(visible.length, (int index) {
          final MapEntry<String, Duration> item = visible[index];
          final String title = byId[item.key]?.metadata.title ?? 'Document';
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(title),
            trailing: Text(_formatDuration(item.value)),
          );
        }),
      ),
    );
  }
}

Duration _sumActiveTime(Iterable<ReadingSession> sessions) {
  return sessions.fold(
    Duration.zero,
    (Duration total, ReadingSession session) => total + session.activeTime,
  );
}

String _formatDuration(Duration duration) {
  if (duration.inMinutes < 60) return '${duration.inMinutes}m';
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}

String _weekdayLabel(int weekday) => switch (weekday) {
  DateTime.monday => 'M',
  DateTime.tuesday => 'T',
  DateTime.wednesday => 'W',
  DateTime.thursday => 'T',
  DateTime.friday => 'F',
  DateTime.saturday => 'S',
  DateTime.sunday => 'S',
  _ => '',
};
