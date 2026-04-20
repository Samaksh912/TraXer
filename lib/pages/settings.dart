import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Appearance",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.wb_sunny_rounded),
                    title: const Text("Light Mode"),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: currentThemeMode,
                      onChanged: (val) => ref.read(themeModeProvider.notifier).state = val!,
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  ListTile(
                    leading: const Icon(Icons.nightlight_round),
                    title: const Text("Dark Mode"),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: currentThemeMode,
                      onChanged: (val) => ref.read(themeModeProvider.notifier).state = val!,
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  ListTile(
                    leading: const Icon(Icons.phone_android_rounded),
                    title: const Text("System Default"),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: currentThemeMode,
                      onChanged: (val) => ref.read(themeModeProvider.notifier).state = val!,
                    ),
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