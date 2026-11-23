import 'package:flutter/material.dart';

import 'auth_components.dart';
import 'register_screen.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  void _openRegistration(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.paleBlue,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final menteeCard = _RoleCard(
              role: 'mentee',
              icon: Icons.menu_book_outlined,
              tag: 'UNTUK MAHASISWA',
              title: 'Mentee',
              description: 'Temukan beasiswa, kelola persiapan, dan dapatkan arahan dari mentor.',
              points: const [
                'Informasi beasiswa terkurasi',
                'Bookmark dan tracker',
                'Bimbingan mentor',
              ],
              onPressed: () => _openRegistration(context, 'mentee'),
            );
            final mentorCard = _RoleCard(
              role: 'mentor',
              icon: Icons.people_outline,
              tag: 'UNTUK PEMBIMBING',
              title: 'Mentor',
              description: 'Bagikan pengalaman dan dampingi mahasiswa mencapai tujuan pendidikannya.',
              points: const [
                'Atur jadwal mentoring',
                'Tinjau permintaan sesi',
                'Bimbing Mentee',
              ],
              onPressed: () => _openRegistration(context, 'mentor'),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst),
                          icon: const Icon(Icons.arrow_back, size: 17),
                          label: const Text('Kembali ke Beranda'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const BeaskitLogo(),
                      const SizedBox(height: 40),
                      const Text(
                        'PILIH PERAN',
                        style: TextStyle(
                          color: AuthPalette.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Daftar sebagai apa?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AuthPalette.navy,
                          fontSize: wide ? 32 : 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih peran yang sesuai dengan perjalananmu di Beaskit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AuthPalette.muted),
                      ),
                      const SizedBox(height: 28),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: menteeCard),
                            const SizedBox(width: 18),
                            Expanded(child: mentorCard),
                          ],
                        )
                      else
                        Column(
                          children: [
                            menteeCard,
                            const SizedBox(height: 16),
                            mentorCard,
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.points,
    required this.onPressed,
  });

  final String role;
  final IconData icon;
  final String tag;
  final String title;
  final String description;
  final List<String> points;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isMentee = role == 'mentee';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4EBF5)),
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: AuthPalette.navy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: isMentee
                  ? const LinearGradient(
                      colors: [Color(0xFFEAF3FF), Color(0xFFD8E8FF)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF102E63), Color(0xFF2864F0)],
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isMentee ? AuthPalette.blue : Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            tag,
            style: const TextStyle(
              color: AuthPalette.blue,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AuthPalette.navy,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AuthPalette.muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Color(0xFF20A66A), size: 15),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: AuthPalette.muted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isMentee
                ? FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AuthPalette.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Daftar sebagai Mentee'),
                  )
                : OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AuthPalette.navy,
                      side: const BorderSide(color: AuthPalette.border),
                    ),
                    child: const Text('Daftar sebagai Mentor'),
                  ),
          ),
        ],
      ),
    );
  }
}
