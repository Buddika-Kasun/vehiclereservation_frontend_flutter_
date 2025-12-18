import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('Icon.png', height: 120),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.yellow),
          ],
        ),
      ),
    );
  }
}
