import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'menu.dart';
import 'homepage.dart';
import 'text_model.dart';
import 'settings.dart';
import 'onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application entry point.
/// 
/// Initializes the Flutter binding, configures system-wide settings,
/// and launches the root app widget.
/// 
/// This function:
/// 1. Ensures Flutter is properly initialized
/// 2. Locks the app to portrait orientation
/// 3. Configures transparent status bar
/// 4. Runs the main application widget
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Force status bar to be transparent
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

/// State for the root MyApp widget.
///
/// Manages:
/// - First-run detection for showing onboarding
/// - Theme mode preferences (light/dark)
/// - Global app configuration
/// - App-wide theme definitions
/// - Primary navigation routes
class _MyAppState extends State<MyApp> {

  // True for first-time app users, false for returning users.
  bool _showOnboarding = true;
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _loadThemePreference();
  }

  /// Determines if this is the first time the app has been launched.
  /// 
  /// Checks SharedPreferences for a 'first_time' flag and sets
  /// _showOnboarding accordingly. After checking, the flag is set
  /// to false for future launches.
  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final firstTime = prefs.getBool('first_time') ?? true;

    if (mounted) {
      setState(() {
        _showOnboarding = firstTime;
      });
    }

    if (firstTime) {
      await prefs.setBool('first_time', false);
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('darkMode') ?? true;

    if (mounted) {
      setState(() {
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  void updateThemeMode(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  /// Builds the root MaterialApp with themes and navigation routes.
  /// 
  /// Creates the MaterialApp with:
  /// - Dark and light theme definitions
  /// - Initial route based on whether onboarding should be shown
  /// - Route definitions for all main app screens
  /// - Global app title and banner settings
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Speak Sight',
      themeMode: _themeMode,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF0080FF),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF0080FF),
          secondary: Color(0xFFFF8000),
          surface: Color(0xFF121212),
          background: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0080FF),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 20, color: Colors.white),
          titleLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 30,
        ),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF0080FF),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF0080FF),
          secondary: Color(0xFFFF8000),
          surface: Colors.white,
          background: Color(0xFFF5F5F5),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF0080FF),
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0080FF),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 20, color: Colors.black87),
          titleLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF0080FF),
          size: 30,
        ),
      ),
      initialRoute: _showOnboarding ? '/onboarding' : '/',
      routes: {
        '/': (context) => MenuPage(),
        '/home': (context) => Homepage(),
        // '/textModel': (context) => TextModelPage(),
        '/settings': (context) => SettingsPage(
          updateThemeMode: updateThemeMode,
        ),
        '/onboarding': (context) => OnboardingPage(key:UniqueKey()),
      },
    );
  }
}