import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BeaskitApp());
}

class BeaskitApp extends StatelessWidget {
  const BeaskitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beaskit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      // Satu pintu masuk: AuthGate memilih halaman sesuai status login dan role.
      initialRoute: '/',
      routes: {'/': (context) => const AuthGate()},
    );
  }
}
