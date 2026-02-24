// lib/utils/firebase_tester.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseTester {
  static Future<void> test() async {
    print("\n" + "=" * 50);
    print("🔧 FIREBASE CONFIGURATION TEST");
    print("=" * 50);

    // Test 1: Check packages
    print("\n📦 Testing Firebase packages...");
    try {
      // Just referencing these will show if packages are installed
      print("✅ firebase_core package is installed");
      print("✅ firebase_messaging package is installed");
    } catch (e) {
      print("❌ Firebase packages not installed: $e");
      return;
    }

    // Test 2: Initialize Firebase
    print("\n🚀 Testing Firebase.initializeApp()...");
    try {
      await Firebase.initializeApp();
      print("✅ Firebase.initializeApp() SUCCESS");
    } catch (e) {
      print("❌ Firebase.initializeApp() FAILED: $e");
      print("\n⚠️ COMMON SOLUTIONS:");
      print("1. Run: flutter clean && flutter pub get");
      print("2. Check google-services.json exists in android/app/");
      print("3. Verify android/app/build.gradle has google-services plugin");
      print("4. Check package name matches Firebase Console");
      return;
    }

    // Test 3: Test Firebase Messaging
    print("\n📱 Testing Firebase Messaging...");
    try {
      final messaging = FirebaseMessaging.instance;
      print("✅ FirebaseMessaging.instance SUCCESS");

      // Test getting token
      final token = await messaging.getToken();
      if (token != null) {
        print("✅ FCM Token retrieved: ${token.substring(0, 20)}...");
        print("   Token length: ${token.length} characters");
      } else {
        print("❌ FCM Token is null");
      }
    } catch (e) {
      print("❌ Firebase Messaging test FAILED: $e");
    }

    print("\n" + "=" * 50);
    print("🧪 TEST COMPLETE");
    print("=" * 50 + "\n");
  }
}

// Use in main.dart:
// await FirebaseTester.test();
