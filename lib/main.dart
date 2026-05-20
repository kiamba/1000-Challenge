import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'firebase_options.dart'; 

// Import your custom application screens and local notification services
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🎯 SURGICAL FIX: Prevent execution freeze from native duplicate-app crash
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // Gracefully consume the existing default instance
    }
  } catch (e) {
    debugPrint("Firebase intercepted native initialization safely: $e");
  }

  // 🎯 GOOGLE ADMOB INITIALIZATION ENGINE
  try {
    await MobileAds.instance.initialize();
    debugPrint("Google Mobile Ads SDK initialized successfully.");
  } catch (e) {
    debugPrint("Google Mobile Ads initialization deferred safely: $e");
  }

  // 🛰️ OFFLINE STORAGE PROVISIONING
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 104857600, // Balanced 100MB static cache allocation bounds
    );
  } catch (e) {
    debugPrint("Firestore persistent configuration deferred: $e");
  }

  // ⏰ LOCAL ALERT PROCESSING ENGINE BOUNDS
  try {
    final notificationEngine = LocalNotificationEngine();
    await notificationEngine.initializeNotifications();
  } catch (e) {
    debugPrint("Notification engine registration deferred: $e");
  }

  // 🚀 EXECUTION HANDOFF
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) { 
    return MaterialApp(
      title: '1000 Challenge Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final LocalNotificationEngine _notificationEngine = LocalNotificationEngine();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Render a system scaffold if the authentication handshake is computing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Active authenticated user routing pipeline configuration bounds
        if (snapshot.hasData && snapshot.data != null) {
          final String currentUserId = snapshot.data!.uid;
          
          // Execute background analytical scanning thread patterns safely
          _notificationEngine.checkAndTriggerAlerts(currentUserId);

          return const DashboardScreen();
        }

        // Default layout falling back strictly to security credentials portal
        return const LoginScreen();
      },
    );
  }
}