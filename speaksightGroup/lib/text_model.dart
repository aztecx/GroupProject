import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class TextModelPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Text Recognition')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 100, color: Colors.white),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () => Vibration.vibrate(duration: 50),
              onDoubleTap: () {
                Vibration.vibrate(duration: 100);
                Navigator.pop(context);
              },
              child: Icon(Icons.touch_app, size: 50, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
