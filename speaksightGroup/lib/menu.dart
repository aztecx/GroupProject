import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speak Sight')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _menuButton(context, 'Start Object Detection', '/home'),
          _menuButton(context, 'Text Recognition', '/textModel'),
          _menuButton(context, 'Settings', '/settings'),
        ],
      ),
    );
  }

  Widget _menuButton(BuildContext context, String title, String route) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          textStyle: TextStyle(fontSize: 20),
        ),
        onPressed: () => Navigator.pushNamed(context, route),
        child: Text(title),
      ),
    );
  }
}
