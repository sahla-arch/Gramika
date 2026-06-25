import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD-Ny3w5MYN3v18jUeKvrWciNn-JuZy_jg',
    appId: '1:572508913061:web:gramikafc1b3',
    messagingSenderId: '572508913061',
    projectId: 'gramika-fc1b3',
    authDomain: 'gramika-fc1b3.firebaseapp.com',
    storageBucket: 'gramika-fc1b3.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-Ny3w5MYN3v18jUeKvrWciNn-JuZy_jg',
    appId: '1:572508913061:android:eddb85a4fa0c7890c9fc4c',
    messagingSenderId: '572508913061',
    projectId: 'gramika-fc1b3',
    storageBucket: 'gramika-fc1b3.firebasestorage.app',
  );
}
