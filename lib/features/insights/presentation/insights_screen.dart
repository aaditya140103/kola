import 'package:flutter/material.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              const _MetricGrid(),
              const SizedBox(height: KolaSpacing.xl),
              Text('Last 7 days', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: KolaSpacing.md),
              const _WeekChart(),
              const SizedBox(height: KolaSpacing.xl),
              Text('Most read', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: KolaSpacing.md),
              const _MostReadList(),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    const List<(String, String, IconData)> metrics = <(String, String, IconData)>[
      ('Today', '42 min', Icons.today_rounded),
      ('This week', '4h 18m', Icons.date_range_rounded),
      ('Completed', '6', Icons.task_alt_rounded),
      ('Annotations', '38', Icons.edit_note_rounded),
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
  const _WeekChart();

  @override
  Widget build(BuildContext context) {
    const List<double> values = <double>[0.42, 0.7, 0.28, 0.92, 0.54, 0.78, 0.61];
    const List<String> labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(KolaSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(values.length, (int index) {
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
                            heightFactor: values[index],
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
                      Text(labels[index], style: Theme.of(context).textTheme.labelMedium),
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
  const _MostReadList();

  @override
  Widget build(BuildContext context) {
    const List<(String, String)> items = <(String, String)>[
      ('The Design of Everyday Things', '5h 24m'),
      ('Rust for Rustaceans', '4h 12m'),
      ('GPU Architecture Notes', '3h 48m'),
    ];

    return Card(
      child: Column(
        children: List<Widget>.generate(items.length, (int index) {
          final (String title, String time) = items[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(title),
            trailing: Text(time),
          );
        }),
      ),
    );
  }
}
