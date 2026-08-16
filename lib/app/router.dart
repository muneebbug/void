import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/features/collections/presentation/widgets/collection_view.dart';
import 'package:void_app/features/collections/presentation/widgets/home_lists_view.dart';
import 'package:void_app/features/media_search/presentation/widgets/media_search_view.dart';
import 'package:void_app/features/search/presentation/widgets/search_view.dart';
import 'package:void_app/features/settings/presentation/widgets/settings_view.dart';
import 'package:void_app/shared/widgets/desktop_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return DesktopLayout(
          currentRoute: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeListsView(),
          ),
        ),
        GoRoute(
          path: '/collection/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return NoTransitionPage(
              key: state.pageKey,
              child: CollectionView(collectionId: id),
            );
          },
        ),
        GoRoute(
          path: '/collection/:id/search',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return NoTransitionPage(
              key: state.pageKey,
              child: MediaSearchView(collectionId: id),
            );
          },
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SearchView(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SettingsView(),
          ),
        ),
      ],
    ),
  ],
);
