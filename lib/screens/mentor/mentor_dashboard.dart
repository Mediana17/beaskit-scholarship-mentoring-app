import 'package:flutter/material.dart';

import '../../models/mentor_profile.dart';
import '../../services/auth_service.dart';
import '../../services/mentor_profile_service.dart';
import 'mentor_booking_screen.dart';
import 'mentor_profile_screen.dart';
import 'schedule_manage_screen.dart';

class MentorDashboard extends StatelessWidget {
  const MentorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = MentorProfileService();
    final uid = profileService.currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beaskit - Mentor'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: FutureBuilder<MentorProfile?>(
        future: profileService.getProfile(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Data profil mentor tidak dapat dimuat.'),
            );
          }
          final profile = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.school, size: 70, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Selamat Datang, Mentor!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _VerificationStatus(profile: profile),
                  const SizedBox(height: 24),
                  _MentorMenuItem(
                    icon: Icons.person,
                    title: 'Perbarui Profil & Kontak',
                    subtitle: 'Ubah informasi profil dan kontak mentor',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MentorProfileScreen(),
                      ),
                    ),
                  ),
                  if (profile.verificationStatus == 'verified') ...[
                    _MentorMenuItem(
                      icon: Icons.calendar_month,
                      title: 'Kelola Jadwal',
                      subtitle: 'Tambah dan atur ketersediaan sesi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScheduleManageScreen(mentorUid: uid),
                        ),
                      ),
                    ),
                    _MentorMenuItem(
                      icon: Icons.people,
                      title: 'Daftar Mentee',
                      subtitle: 'Lihat mentee dan booking yang masuk',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MentorBookingScreen(mentorUid: uid),
                        ),
                      ),
                    ),
                    _MentorMenuItem(
                      icon: Icons.event_available,
                      title: 'Booking Mentor',
                      subtitle: 'Setujui dan kelola sesi mentoring',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MentorBookingScreen(mentorUid: uid),
                        ),
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Fitur pengelolaan jadwal dan booking tersedia '
                        'setelah profil mentor terverifikasi.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerificationStatus extends StatelessWidget {
  const _VerificationStatus({required this.profile});

  final MentorProfile profile;

  @override
  Widget build(BuildContext context) {
    switch (profile.verificationStatus) {
      case 'verified':
        return const Card(
          child: ListTile(
            leading: Icon(Icons.verified, color: Colors.green),
            title: Text('Status: Mentor terverifikasi'),
            subtitle: Text('Kamu sudah dapat menggunakan fitur mentor.'),
          ),
        );
      case 'rejected':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Status: Verifikasi ditolak'),
            subtitle: Text(
              profile.rejectionReason ?? 'Silakan periksa kembali profil kamu.',
            ),
          ),
        );
      default:
        return const Card(
          child: ListTile(
            leading: Icon(Icons.hourglass_top, color: Colors.orange),
            title: Text('Status: Menunggu verifikasi'),
            subtitle: Text('Profil kamu sedang menunggu persetujuan Admin.'),
          ),
        );
    }
  }
}

class _MentorMenuItem extends StatelessWidget {
  const _MentorMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Icon(icon, size: 28),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    ),
  );
}
