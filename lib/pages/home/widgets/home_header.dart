import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.onSettingsTap,
  });

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF40485D).withValues(alpha: 0.3),
                ),
                color: const Color(0xFF111827),
              ),
              child: Icon(profile.avatarIcon, color: const Color(0xFF9EFFC8)),
            ),
            const SizedBox(width: 12),
            Text(
              profile.displayName.trim().isEmpty ? 'EXPNSE' : profile.displayName,
              style: TextStyle(
                color: Color(0xFF9EFFC8),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onSettingsTap,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.settings_outlined, color: Color(0xFF9EFFC8)),
          ),
        ),
      ],
    );
  }
}

