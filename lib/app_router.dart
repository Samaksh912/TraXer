import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/homepage.dart';
import 'pages/settings.dart';
import 'Auth/screens/loginpage.dart';
import 'Auth/screens/signuppage.dart';
import 'providers/auth_provider.dart';

class AppRoutes {
  static const String homeName = 'home';
  static const String settingsName = 'settings';
  static const String loginName = 'login';
  static const String signupName = 'signup';

  static const String homePath = '/';
  static const String settingsPath = '/settings';
  static const String loginPath = '/login';
  static const String signupPath = '/signup';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.homePath,
    redirect: (BuildContext context, GoRouterState state) {
      // If the auth state is still loading, we don't redirect yet
      if (authState.isLoading) return null;

      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.matchedLocation == AppRoutes.loginPath || state.matchedLocation == AppRoutes.signupPath;

      if (!isAuthenticated && !isLoggingIn) {
        return AppRoutes.loginPath;
      }
      
      if (isAuthenticated && isLoggingIn) {
        return AppRoutes.homePath;
      }

      return null;
    },
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
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.signupPath,
        name: AppRoutes.signupName,
        builder: (BuildContext context, GoRouterState state) {
          return const SignupPage();
        },
      ),
    ],
  );
});
