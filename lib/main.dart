import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:traxer/pages/homepage.dart';
import 'firebase_options.dart';
import 'models/isarexpense.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxer/Auth/screens/loginpage.dart';
// Global Theme Controller
final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.system);
// Global variable to access DB anywhere (Simple approach)
late Isar isar;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. Get the document directory
  final dir = await getApplicationDocumentsDirectory();

  // 2. Open Isar
  isar = await Isar.open(
    [IsarExpenseSchema], // Pass generated schema
    directory: dir.path,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Voice Expense Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
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
          home: const HomePage()
          // home: StreamBuilder<User?>(
          //   stream: FirebaseAuth.instance.authStateChanges(),
          //   builder: (ctx, snap) {
          //     return snap.hasData ? const HomePage() : const LoginPage();
        //     },
        //   ),
         );
      },
    );
  }
}

//todo fix  add login page,theme problem, add a database which will probably be local,make things responsive, add login page