// Salin file ini menjadi lib/firebase_options.dart lalu isi nilainya dari
// Firebase Console > Project settings > Your apps > Web app.
// ATAU jalankan:  flutterfire configure --project=beaskit-a210e
// File lib/firebase_options.dart sudah di-gitignore, jangan di-commit.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Hanya platform web yang dikonfigurasi.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'ISI_API_KEY',
    appId: 'ISI_APP_ID',
    messagingSenderId: 'ISI_SENDER_ID',
    projectId: 'beaskit-a210e',
    authDomain: 'beaskit-a210e.firebaseapp.com',
    storageBucket: 'beaskit-a210e.firebasestorage.app',
  );
}
