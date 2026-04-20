import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final navBarVisibleProvider = StateProvider<bool>((ref) => true);
final monthlySpendingViewProvider = StateProvider<bool>((ref) => true);

