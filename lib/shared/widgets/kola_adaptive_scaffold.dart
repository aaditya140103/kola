import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';

class KolaAdaptiveScaffold extends StatelessWidget {
  const KolaAdaptiveScaffold({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const List<_KolaDestination> _destinations = <_KolaDestination>[
    _KolaDestination('Home', Icons.home_rounded, '/'),
    _KolaDestination('Library', Icons.local_library_rounded, '/library'),
    _KolaDestination('Search', Icons.search_rounded, '/search'),
    _KolaDestination('Insights', Icons.insights_rounded, '/insights'),
  ];

  int get _selectedIndex {
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/insights')) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final bool compact = width < KolaBreakpoints.compact;
        final bool extended = width >= KolaBreakpoints.expanded;

        if (compact) {
          return Scaffold(
            body: SafeArea(child: child),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) => _navigate(context, index),
              destinations: _destinations
                  .map(
                    (_KolaDestination destination) => NavigationDestination(
                      icon: Icon(destination.icon),
                      label: destination.label,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(KolaSpacing.sm),
                  child: NavigationRail(
                    extended: extended,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) => _navigate(context, index),
                    leading: Padding(
                      padding: const EdgeInsets.only(bottom: KolaSpacing.md),
                      child: _KolaMark(showWordmark: extended),
                    ),
                    destinations: _destinations
                        .map(
                          (_KolaDestination destination) => NavigationRailDestination(
                            icon: Icon(destination.icon),
                            label: Text(destination.label),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KolaMark extends StatelessWidget {
  const _KolaMark({required this.showWordmark});

  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: KolaRadius.sm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(KolaSpacing.xs),
            child: Icon(Icons.menu_book_rounded, color: scheme.onPrimary),
          ),
        ),
        if (showWordmark) ...<Widget>[
          const SizedBox(width: KolaSpacing.sm),
          Text('Kola', style: Theme.of(context).textTheme.titleLarge),
        ],
      ],
    );
  }
}

class _KolaDestination {
  const _KolaDestination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
