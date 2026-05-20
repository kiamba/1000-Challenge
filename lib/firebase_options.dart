import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // 🌐 1. WEB ARCHITECTURE CONFIGURATION PASSPORT
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAD9Pc5-RpOOkf9CekjVtPfk2x0KuBJuMQ', // 💡 Paste the Web API Key from your browser screen here
    authDomain: 'challenge-a80ee.firebaseapp.com',
    projectId: 'challenge-a80ee',
    storageBucket: 'challenge-a80ee.firebasestorage.app',
    messagingSenderId: '53921512304',
    appId: '1:53921512304:web:7ced174960a18f9babedb5', // 💡 Paste your Web App ID here
  );

  // 🤖 2. NATIVE ANDROID MOBILE PHONE ENTRY REGISTRY
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4_YOUR_ANDROID_API_KEY_HERE', 
    authDomain: 'challenge-a80ee.firebaseapp.com',
    projectId: 'challenge-a80ee',
    storageBucket: 'challenge-a80ee.firebasestorage.app',
    messagingSenderId: '53921512304',
    appId: '1:53921512304:android:YOUR_ANDROID_APP_ID_HERE',
  );

  // 🍏 3. NATIVE iOS PHONE ENTRY REGISTRY
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA4_YOUR_IOS_API_KEY_HERE',
    authDomain: 'challenge-a80ee.firebaseapp.com',
    projectId: 'challenge-a80ee',
    storageBucket: 'challenge-a80ee.firebasestorage.app',
    messagingSenderId: '53921512304',
    appId: '1:53921512304:ios:YOUR_IOS_APP_ID_HERE',
    iosBundleId: 'com.example.challenge',
  );
}