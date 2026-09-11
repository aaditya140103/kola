import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/features/home/presentation/home_screen.dart';
import 'package:kola/features/insights/presentation/insights_screen.dart';
import 'package:kola/features/library/presentation/library_screen.dart';
import 'package:kola/features/reader/presentation/reader_screen.dart';
import 'package:kola/features/search/presentation/search_screen.dart';
import 'package:kola/shared/widgets/kola_adaptive_scaffold.dart';

final GoRouter kolaRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return KolaAdaptiveScaffold(location: state.uri.path, child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (BuildContext context, GoRouterState state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (BuildContext context, GoRouterState state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/insights',
          builder: (BuildContext context, GoRouterState state) => const InsightsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/reader/:documentId',
      builder: (BuildContext context, GoRouterState state) {
        return ReaderScreen(documentId: state.pathParameters['documentId'] ?? 'unknown');
      },
    ),
  ],
);
