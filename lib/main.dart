import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'app_router.dart';
import 'core/config/supabase_config.dart';
import 'models/app_sync_state.dart';
import 'models/auth_user.dart';
import 'models/isar_expense.dart';
import 'models/sync_queue_item.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_providers.dart';
import 'services/connectivity_sync_trigger.dart';
import 'services/isar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    SupabaseConfig.validate();
    await sb.Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
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
  } catch (error, stackTrace) {
    debugPrint('App bootstrap failed: $error\n$stackTrace');
    runApp(_BootstrapErrorApp(error: error));
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Startup failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The app could not finish bootstrapping.\n\n$error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Check your .env file and local storage access, then restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<AuthUser?>? _authSubscription;
  ConnectivitySyncTrigger? _connectivitySyncTrigger;
  String? _bootstrappedUserId;
  bool _isBootstrappingUser = false;

  @override
  void initState() {
    super.initState();
    final authService = ref.read(authServiceProvider);
    _authSubscription = authService.authStateChanges.listen((user) {
      unawaited(_handleAuthState(user));
    });
    unawaited(_handleAuthState(authService.currentUser));
  }

  @override
  void dispose() {
    unawaited(_connectivitySyncTrigger?.dispose() ?? Future<void>.value());
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleAuthState(AuthUser? user) async {
    if (user == null) {
      _bootstrappedUserId = null;
      await _connectivitySyncTrigger?.dispose();
      _connectivitySyncTrigger = null;
      ref.read(profileProvider.notifier).state = const ProfileState(
        displayName: 'EXPNSE',
        avatarIcon: Icons.person,
      );
      return;
    }

    if (_bootstrappedUserId == user.id || _isBootstrappingUser) {
      return;
    }

    _isBootstrappingUser = true;
    try {
      final repository = ref.read(expenseRepositoryProvider);
      final syncService = ref.read(syncServiceProvider);
      final syncedUserId = await repository.getSyncedUserId();

      if (syncedUserId != null && syncedUserId != user.id) {
        await repository.clearUserData();
      }

      ref.read(profileProvider.notifier).state = const ProfileState(
        displayName: 'EXPNSE',
        avatarIcon: Icons.person,
      );

      await syncService.ensureUserDocument();

      final hasCompletedInitialSync =
          await repository.hasCompletedInitialSyncForUser(user.id);

      if (!hasCompletedInitialSync) {
        await syncService.initialSync();
        await repository.setInitialSyncCompletedForUser(user.id);
      }

      await _connectivitySyncTrigger?.dispose();
      _connectivitySyncTrigger = ConnectivitySyncTrigger(syncService: syncService)
        ..init();
      _bootstrappedUserId = user.id;
    } catch (error, stackTrace) {
      debugPrint('Failed to bootstrap sync for ${user.id}: $error\n$stackTrace');
    } finally {
      _isBootstrappingUser = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Voice Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      routerConfig: router,
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
