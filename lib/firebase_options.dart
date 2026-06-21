import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4W0Rq_Rd7c7zmh-Vuw8YV9v4WDFCgoeI',
    authDomain: 'hawwil2.firebaseapp.com',
    projectId: 'hawwil2',
    storageBucket: 'hawwil2.firebasestorage.app',
    messagingSenderId: '350634992471',
    appId: '1:350634992471:web:96e296f582dda728829412',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlhLpqJHWyP7pHrZ7wyQw1pd7CRq5u_BQ',
    authDomain: 'hawwil2.firebaseapp.com',
    projectId: 'hawwil2',
    storageBucket: 'hawwil2.firebasestorage.app',
    messagingSenderId: '350634992471',
    appId: '1:350634992471:android:90fec3374163c0e7829412',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyARfY8MI3XMRdHblp1-YwNE8y3fP8XAPrg',
    authDomain: 'hawwil2.firebaseapp.com',
    projectId: 'hawwil2',
    storageBucket: 'hawwil2.firebasestorage.app',
    messagingSenderId: '350634992471',
    appId: '1:350634992471:ios:48079ee260663f58829412',
    iosClientId: '350634992471-b4m00ar1lt04qk7llisrefjpku6d4h4g.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyARfY8MI3XMRdHblp1-YwNE8y3fP8XAPrg',
    authDomain: 'hawwil2.firebaseapp.com',
    projectId: 'hawwil2',
    storageBucket: 'hawwil2.firebasestorage.app',
    messagingSenderId: '350634992471',
    appId: '1:350634992471:ios:48079ee260663f58829412',
    iosClientId: '350634992471-b4m00ar1lt04qk7llisrefjpku6d4h4g.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );
}
