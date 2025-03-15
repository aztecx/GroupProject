/// This File is the Main Entry point to our Speak Sight app.
///
/// This file initializes the Flutter application by creating a MaterialApp
/// which is essential in any Flutter Project. the Material App is equipped
/// with a custom theme and a set of defined routes which represents the different pages in the repo.
/// Speak Sight is designed to assist visually impaired users with features
/// like real-time object detection (via YOLO), text recognition, TTS and STT functionality and more.
import 'package:flutter/material.dart';
import 'menu.dart';
import 'homepage.dart';
import 'text_model.dart';
import 'settings.dart';
import 'test_model.dart';
import 'package:speaksightgroup/yolo_service.dart';

/// The main function which starts the application by calling runApp.
void main() {
  runApp(MyApp());
}

/// MyApp is the root widget of tth application. WE are building the MaterialAPP
/// here with the custom routes for the pages
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Disable the debug banner for a cleaner look.
      debugShowCheckedModeBanner: false,
      // The title of the application.
      title: 'Speak Sight',
      // Define a custom theme for the app.
      theme: ThemeData(
        // Primary color scheme set to indigo.
        primarySwatch: Colors.indigo,
        // Dark scaffold background for better contrast.
        scaffoldBackgroundColor: Colors.black,
        // Custom text theme for consistent styling.
        textTheme: TextTheme(
          // Style for general body text.
          bodyLarge: TextStyle(fontSize: 20, color: Colors.white),
          // Style for large titles.
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      // Set the initial route to the MenuPage.
      initialRoute: '/',
      // Define the app's routes, mapping route names to widget builders.
      routes: {
        '/': (context) => MenuPage(),           // Main menu page.
        '/home': (context) => Homepage(),         // Object detection page.
        '/textModel': (context) => TextModelPage(), // Text recognition page.
        '/settings': (context) => SettingsPage(),   // Settings page.
        '/testText': (context) => TestTextPage(),     // Test page since the prof needed something for that (delete later for the official release)
      },
    );
  }
}
