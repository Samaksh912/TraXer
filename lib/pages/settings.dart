import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.system);
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      groupValue: _themeNotifier.value,
                      onChanged: (val) => _themeNotifier.value = val!,
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  ListTile(
                    leading: const Icon(Icons.nightlight_round),
                    title: const Text("Dark Mode"),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: _themeNotifier.value,
                      onChanged: (val) => _themeNotifier.value = val!,
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  ListTile(
                    leading: const Icon(Icons.phone_android_rounded),
                    title: const Text("System Default"),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: _themeNotifier.value,
                      onChanged: (val) => _themeNotifier.value = val!,
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