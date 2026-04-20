import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app_router.dart';
import 'firebase_options.dart';
import 'models/app_sync_state.dart';
import 'models/isar_expense.dart';
import 'models/sync_queue_item.dart';
import 'providers/app_providers.dart';
import 'providers/expense_providers.dart';
import 'services/connectivity_sync_trigger.dart';
import 'services/isar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. Get the document directory
  final dir = await getApplicationDocumentsDirectory();

  // 2. Open Isar
  isar = await Isar.open(
    [
      IsarExpenseSchema,
      SyncQueueItemSchema,
      AppSyncStateSchema,
    ],
    directory: dir.path,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<User?>? _authSubscription;
  ConnectivitySyncTrigger? _connectivitySyncTrigger;
  String? _bootstrappedUserId;
  bool _isBootstrappingUser = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(_handleAuthState(user));
    });
    unawaited(_handleAuthState(FirebaseAuth.instance.currentUser));
  }

  @override
  void dispose() {
    unawaited(_connectivitySyncTrigger?.dispose() ?? Future<void>.value());
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleAuthState(User? user) async {
    if (user == null) {
      _bootstrappedUserId = null;
      await _connectivitySyncTrigger?.dispose();
      _connectivitySyncTrigger = null;
      return;
    }

    if (_bootstrappedUserId == user.uid || _isBootstrappingUser) {
      return;
    }

    _isBootstrappingUser = true;
    try {
      final repository = ref.read(expenseRepositoryProvider);
      final syncService = ref.read(syncServiceProvider);
      final hasCompletedInitialSync =
          await repository.hasCompletedInitialSyncForUser(user.uid);

      if (!hasCompletedInitialSync) {
        await syncService.initialSync();
        await repository.setInitialSyncCompletedForUser(user.uid);
      }

      await _connectivitySyncTrigger?.dispose();
      _connectivitySyncTrigger = ConnectivitySyncTrigger(syncService: syncService)
        ..init();
      _bootstrappedUserId = user.uid;
    } catch (error, stackTrace) {
      debugPrint('Failed to bootstrap sync for ${user.uid}: $error\n$stackTrace');
    } finally {
      _isBootstrappingUser = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Voice Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      routerConfig: appRouter,
      // LIGHT THEME
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2D3142)),
          bodyMedium: TextStyle(color: Color(0xFF2D3142)),
        ),
      ),
      // DARK THEME
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
