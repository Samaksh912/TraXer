import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class ProfileState {
  const ProfileState({
	required this.displayName,
	required this.avatarIcon,
  });

  final String displayName;
  final IconData avatarIcon;

  ProfileState copyWith({
	String? displayName,
	IconData? avatarIcon,
  }) {
	return ProfileState(
	  displayName: displayName ?? this.displayName,
	  avatarIcon: avatarIcon ?? this.avatarIcon,
	);
  }
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final navBarVisibleProvider = StateProvider<bool>((ref) => true);
final monthlySpendingViewProvider = StateProvider<bool>((ref) => true);
final profileProvider = StateProvider<ProfileState>((ref) {
  return const ProfileState(
	displayName: 'EXPNSE',
	avatarIcon: Icons.person,
  );
});

