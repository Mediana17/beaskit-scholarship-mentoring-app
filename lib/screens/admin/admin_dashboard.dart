import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'mentor_verification_screen.dart';
import 'scholarship_manage_screen.dart';
import 'user_manage_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beaskit Admin'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => AuthService().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AdminMenuCard(
                icon: Icons.school_outlined,
                title: 'Pengelolaan Beasiswa',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScholarshipManageScreen(),
                  ),
                ),
              ),
              _AdminMenuCard(
                icon: Icons.verified_user_outlined,
                title: 'Verifikasi Mentor',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MentorVerificationScreen()),
                ),
              ),
              _AdminMenuCard(
                icon: Icons.people_outline,
                title: 'Pengguna',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserManageScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Icon(icon, size: 30),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    ),
  );
}
