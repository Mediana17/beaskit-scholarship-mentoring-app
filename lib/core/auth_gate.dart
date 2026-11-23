import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/auth/public_landing_screen.dart';
import '../screens/mentee/mentee_dashboard.dart';
import '../screens/mentor/mentor_dashboard.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Menentukan halaman awal: belum login -> halaman publik; sudah login -> dashboard sesuai role.
/// Saat login/logout, halaman berganti otomatis (tidak perlu Navigator manual).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Status(message: 'Memuat...', showLogout: false);
        }
        final user = authSnap.data;
        if (user == null) return const PublicLandingScreen();

        return StreamBuilder<UserModel?>(
          stream: UserService().watchUser(user.uid),
          builder: (context, snap) {
            if (snap.hasError) {
              return const _Status(
                message: 'Gagal memuat profil. Periksa koneksi internet Anda.',
              );
            }
            final me = snap.data;
            if (snap.connectionState == ConnectionState.waiting || me == null) {
              return const _Status(message: 'Menyiapkan akun...');
            }
            switch (me.role) {
              case 'mentee':
                return MenteeDashboard(user: me);
              case 'mentor':
                return const MentorDashboard();
              case 'admin':
                return const AdminDashboard();
              default:
                return const _Status(message: 'Role pengguna tidak dikenali.');
            }
          },
        );
      },
    );
  }
}

class _Status extends StatelessWidget {
  final String message;
  final bool showLogout;
  const _Status({required this.message, this.showLogout = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
            if (showLogout) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => AuthService().logout(),
                child: const Text('Keluar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
