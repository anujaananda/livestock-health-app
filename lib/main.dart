import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_theme.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // ✅ Load saved theme BEFORE app starts
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;

  runApp(
    MultiProvider(
      providers: [Provider<AuthService>(create: (_) => AuthService())],
      child: MyApp(initialDarkMode: isDark),
    ),
  );
}

// ============================================================
// ✅ GLOBAL THEME NOTIFIER
// ============================================================
class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeNotifier(bool initial) : _isDarkMode = initial;

  bool get isDarkMode => _isDarkMode;

  void toggle(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  final bool initialDarkMode;

  const MyApp({super.key, required this.initialDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeNotifier(widget.initialDarkMode);
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeNotifier>.value(
      value: _themeNotifier,
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Livestock Health App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
