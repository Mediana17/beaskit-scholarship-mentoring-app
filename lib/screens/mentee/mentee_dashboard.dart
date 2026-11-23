import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'bookmark_screen.dart';
import 'booking_status_screen.dart';
import 'mentor_directory_page.dart';
import 'scholarship_list_screen.dart';
import 'tracker_list_screen.dart';

class MenteeDashboard extends StatelessWidget {
  final UserModel user;
  const MenteeDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beaskit'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user.name}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Temukan beasiswa dan siapkan pendaftaranmu.'),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _MenuCard(
                      icon: Icons.search,
                      title: 'Cari Beasiswa',
                      subtitle: 'Daftar, pencarian, dan detail beasiswa',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScholarshipListScreen(),
                        ),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.bookmark,
                      title: 'Bookmark',
                      subtitle: 'Beasiswa yang kamu simpan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookmarkScreen(),
                        ),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.checklist,
                      title: 'Tracker',
                      subtitle: 'Pantau persiapan beasiswa',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrackerListScreen(),
                        ),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.people,
                      title: 'Mentor & Booking',
                      subtitle: 'Cari mentor dan ajukan jadwal',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MentorDirectoryPage(),
                        ),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.event_note,
                      title: 'Booking Saya',
                      subtitle: 'Lihat dan kelola pengajuan booking',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookingStatusScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
