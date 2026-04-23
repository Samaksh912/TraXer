import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traxer/app_router.dart';
import 'package:traxer/providers/app_providers.dart';

void main() {
  test('go_router constants use expected paths and names', () {
    expect(AppRoutes.homePath, '/');
    expect(AppRoutes.settingsPath, '/settings');
    expect(AppRoutes.homeName, 'home');
    expect(AppRoutes.settingsName, 'settings');
  });

  test('router has at least home and settings routes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routerProvider).configuration.routes.length, greaterThanOrEqualTo(2));
  });

  test('theme mode provider updates shared state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
    container.read(themeModeProvider.notifier).state = ThemeMode.dark;
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('view state providers update without setState', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(navBarVisibleProvider), isTrue);
    expect(container.read(monthlySpendingViewProvider), isTrue);

    container.read(navBarVisibleProvider.notifier).state = false;
    container.read(monthlySpendingViewProvider.notifier).state = false;

    expect(container.read(navBarVisibleProvider), isFalse);
    expect(container.read(monthlySpendingViewProvider), isFalse);
  });
}
