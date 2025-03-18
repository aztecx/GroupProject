import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 import 'menu.dart';
 import 'homepage.dart';
 import 'text_model.dart';
 import 'settings.dart';
 import 'onboarding.dart';
 import 'package:shared_preferences/shared_preferences.dart';
 
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
 
 class _MyAppState extends State<MyApp> {
   bool _showOnboarding = true;
   ThemeMode _themeMode = ThemeMode.dark;
 
   @override
   void initState() {
     super.initState();
     _checkFirstTime();
     _loadThemePreference();
   }
 
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
         '/textModel': (context) => TextModelPage(),
         '/settings': (context) => SettingsPage(
           updateThemeMode: updateThemeMode,
         ),
         '/onboarding': (context) => OnboardingPage(),
       },
     );
   }
 }