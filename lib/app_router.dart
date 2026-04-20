import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/homepage.dart';
import 'pages/settings.dart';

class AppRoutes {
  static const String homeName = 'home';
  static const String settingsName = 'settings';

  static const String homePath = '/';
  static const String settingsPath = '/settings';
}

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.homePath,
      name: AppRoutes.homeName,
      builder: (BuildContext context, GoRouterState state) {
        return const HomePage();
      },
    ),
    GoRoute(
      path: AppRoutes.settingsPath,
      name: AppRoutes.settingsName,
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsPage();
      },
    ),
  ],
);

