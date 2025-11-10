import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/splash_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/auth_manager.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await StorageService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCW RIDE',
      navigatorKey: AuthManager.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: StorageService.hasValidSession,
        builder: (context, snapshot) {
          // Show splash screen while checking session
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          // Handle errors gracefully
          if (snapshot.hasError) {
            print('Session check error: ${snapshot.error}');
            return const LoginScreen();
          }
          
          // Redirect based on session status
          if (snapshot.hasData) {
            return snapshot.data! ? HomeScreen() : LoginScreen();
          }
          
          // Default fallback
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}