import 'package:flutter/material.dart';
import 'package:traxer/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/app_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _nameController = TextEditingController();

  static const _availableIcons = <IconData>[
    Icons.person,
    Icons.person_outline,
    Icons.account_circle,
    Icons.face,
    Icons.badge,
    Icons.star,
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController.text = profile.displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final currentProfile = ref.read(profileProvider);
    final enteredName = _nameController.text.trim();

    ref.read(profileProvider.notifier).state = currentProfile.copyWith(
          displayName: enteredName.isEmpty ? currentProfile.displayName : enteredName,
        );
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsSection(
            title: 'Profile',
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: context.appColors.background,
                  child: Icon(profile.avatarIcon, color: context.appColors.income, size: 34),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  onChanged: (value) {
                    ref.read(profileProvider.notifier).state =
                        profile.copyWith(displayName: value.trim());
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<IconData>(
                  value: profile.avatarIcon,
                  decoration: const InputDecoration(
                    labelText: 'Profile icon',
                    prefixIcon: Icon(Icons.face_outlined),
                  ),
                  items: _availableIcons
                      .map(
                        (icon) => DropdownMenuItem<IconData>(
                          value: icon,
                          child: Row(
                            children: [
                              Icon(icon, size: 20),
                              const SizedBox(width: 12),
                              Text(_iconLabel(icon)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (icon) {
                    if (icon == null) return;
                    ref.read(profileProvider.notifier).state = profile.copyWith(avatarIcon: icon);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save profile'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Appearance',
            child: DropdownButtonFormField<ThemeMode>(
              value: currentThemeMode,
              decoration: const InputDecoration(
                labelText: 'Theme mode',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System default'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light mode'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark mode'),
                ),
              ],
              onChanged: (mode) {
                if (mode == null) return;
                ref.read(themeModeProvider.notifier).state = mode;
              },
            ),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Account',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _iconLabel(IconData icon) {
    if (icon == Icons.person) return 'Person';
    if (icon == Icons.person_outline) return 'Person outline';
    if (icon == Icons.account_circle) return 'Account circle';
    if (icon == Icons.face) return 'Face';
    if (icon == Icons.badge) return 'Badge';
    if (icon == Icons.star) return 'Star';
    return 'Profile icon';
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}