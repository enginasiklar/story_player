// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDhIKas1kF25sLByPs9MjC3ETfXamoqbIk',
    appId: '1:137638127071:web:ff59f84a3b0dc96584d06a',
    messagingSenderId: '137638127071',
    projectId: 'storyplayer-4a21e',
    authDomain: 'storyplayer-4a21e.firebaseapp.com',
    storageBucket: 'storyplayer-4a21e.appspot.com',
    measurementId: 'G-XYPQ5WNQFJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC77MK4xOLE8dP0MC98zWYYaEX82-Zk9bk',
    appId: '1:137638127071:android:6b04b06868c36c0784d06a',
    messagingSenderId: '137638127071',
    projectId: 'storyplayer-4a21e',
    storageBucket: 'storyplayer-4a21e.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApDcZM8n1g8gZHrmU3bGBBj4gzqw-7dMk',
    appId: '1:137638127071:ios:54bfe12af5baf7b984d06a',
    messagingSenderId: '137638127071',
    projectId: 'storyplayer-4a21e',
    storageBucket: 'storyplayer-4a21e.appspot.com',
    iosClientId: '137638127071-pkmptc6p4rv78bbjdbtbjv37ve8ru3gb.apps.googleusercontent.com',
    iosBundleId: 'com.example.androidStudioProjects',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyApDcZM8n1g8gZHrmU3bGBBj4gzqw-7dMk',
    appId: '1:137638127071:ios:54bfe12af5baf7b984d06a',
    messagingSenderId: '137638127071',
    projectId: 'storyplayer-4a21e',
    storageBucket: 'storyplayer-4a21e.appspot.com',
    iosClientId: '137638127071-pkmptc6p4rv78bbjdbtbjv37ve8ru3gb.apps.googleusercontent.com',
    iosBundleId: 'com.example.androidStudioProjects',
  );
}