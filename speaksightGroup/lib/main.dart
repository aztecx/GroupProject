import 'package:flutter/material.dart';
import 'menu.dart';
import 'homepage.dart';
import 'text_model.dart';
import 'settings.dart';
import 'package:speaksightgroup/yolo_service.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Speak Sight',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.black, // Dark background for contrast
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 20, color: Colors.white),
          titleLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MenuPage(),
        '/home': (context) => Homepage(),
        '/textModel': (context) => TextModelPage(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}
