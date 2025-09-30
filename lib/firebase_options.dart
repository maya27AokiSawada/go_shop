// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCiPnY6GaBSrUfnCkFzJu-Y3p7D8Cqg1aI',
    appId: '1:895658199748:web:d24f3552522ea53318d791',
    messagingSenderId: '895658199748',
    projectId: 'gotoshop-572b7',
    authDomain: 'gotoshop-572b7.firebaseapp.com',
    storageBucket: 'gotoshop-572b7.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCiPnY6GaBSrUfnCkFzJu-Y3p7D8Cqg1aI',
    appId: '1:895658199748:android:9bc037ca25d380a018d791',
    messagingSenderId: '895658199748',
    projectId: 'gotoshop-572b7',
    storageBucket: 'gotoshop-572b7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCiPnY6GaBSrUfnCkFzJu-Y3p7D8Cqg1aI',
    appId: '1:895658199748:ios:your_ios_app_id',
    messagingSenderId: '895658199748',
    projectId: 'gotoshop-572b7',
    storageBucket: 'gotoshop-572b7.firebasestorage.app',
    iosBundleId: 'net.sumomo.planning.go.shop',
  );
}