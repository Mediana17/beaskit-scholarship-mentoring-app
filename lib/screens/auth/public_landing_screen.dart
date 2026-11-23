import 'package:flutter/material.dart';

import 'auth_components.dart';
import 'login_screen.dart';
import 'register_role_screen.dart';
import 'register_screen.dart';

class PublicLandingScreen extends StatefulWidget {
  const PublicLandingScreen({super.key});

  @override
  State<PublicLandingScreen> createState() => _PublicLandingScreenState();
}

class _PublicLandingScreenState extends State<PublicLandingScreen> {
  final _featuresKey = GlobalKey();
  final _journeyKey = GlobalKey();

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openRoleSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterRoleScreen()),
    );
  }

  void _openRegistration(String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen(role: role)),
    );
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  Widget _navLink(String label, VoidCallback onPressed) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AuthPalette.navy,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    child: Text(label),
  );

  Widget _header(bool wide) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE9EFF8))),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 28 : 18,
            vertical: 13,
          ),
          child: Row(
            children: [
              const BeaskitLogo(),
              const Spacer(),
              if (wide) ...[
                _navLink('Beranda', () {}),
                _navLink('Knowledge', () => _scrollTo(_featuresKey)),
                _navLink('Tentang Beaskit', () => _scrollTo(_journeyKey)),
                _navLink('Fitur', () => _scrollTo(_featuresKey)),
                const SizedBox(width: 10),
              ],
              TextButton(
                onPressed: _openLogin,
                style: TextButton.styleFrom(
                  foregroundColor: AuthPalette.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text('Masuk'),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _openRoleSelection,
                style: FilledButton.styleFrom(
                  backgroundColor: AuthPalette.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: const Text('Daftar Gratis'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _hero(bool wide) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(
          icon: Icons.auto_awesome,
          text: 'PLATFORM BEASISWA & MENTORING',
        ),
        const SizedBox(height: 22),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Temukan Peluang\nBeasiswa,\n'),
              TextSpan(
                text: 'Wujudkan Masa\nDepanmu.',
                style: TextStyle(color: AuthPalette.blue),
              ),
            ],
          ),
          style: TextStyle(
            color: AuthPalette.navy,
            fontSize: wide ? 55 : 43,
            fontWeight: FontWeight.w600,
            height: 1.03,
            letterSpacing: -1.7,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Temukan informasi beasiswa, kelola persiapan pendaftaran, '
          'dan dapatkan bimbingan dari mentor.',
          style: TextStyle(color: AuthPalette.muted, height: 1.65),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => _openRegistration('mentee'),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Temukan Beasiswa'),
              style: FilledButton.styleFrom(
                backgroundColor: AuthPalette.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => _scrollTo(_featuresKey),
              style: OutlinedButton.styleFrom(
                foregroundColor: AuthPalette.navy,
                side: const BorderSide(color: AuthPalette.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              child: const Text('Pelajari Beaskit'),
            ),
          ],
        ),
      ],
    );

    return Container(
      color: AuthPalette.paleBlue,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 28 : 22,
              52,
              wide ? 28 : 22,
              52,
            ),
            child: wide
                ? Row(
                    children: [
                      Expanded(flex: 11, child: copy),
                      const SizedBox(width: 26),
                      const Expanded(flex: 10, child: _HeroIllustration()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 30),
                      const _HeroIllustration(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _trustStrip(bool wide) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        child: wide
            ? const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Semua kebutuhan persiapan beasiswa dalam satu tempat',
                      style: TextStyle(color: AuthPalette.muted, fontSize: 12),
                    ),
                  ),
                  _TrustLabel('BEASISWA'),
                  _TrustLabel('TRACKER'),
                  _TrustLabel('MENTORING'),
                ],
              )
            : const Wrap(
                spacing: 20,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _TrustLabel('BEASISWA'),
                  _TrustLabel('TRACKER'),
                  _TrustLabel('MENTORING'),
                ],
              ),
      ),
    ),
  );

  Widget _featureSection(bool wide) => Container(
    key: _featuresKey,
    color: Colors.white,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 28 : 22,
            vertical: 70,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow(text: 'MENGAPA BEASKIT'),
              const SizedBox(height: 12),
              Text(
                'Semua kebutuhan persiapanmu\ndalam satu tempat',
                style: TextStyle(
                  color: AuthPalette.navy,
                  fontSize: wide ? 34 : 29,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 570,
                child: Text(
                  'Perjalanan mencari beasiswa terasa lebih jelas, terarah, '
                  'dan tidak dilakukan sendirian.',
                  style: TextStyle(color: AuthPalette.muted, height: 1.55),
                ),
              ),
              const SizedBox(height: 30),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 900
                      ? (constraints.maxWidth - 36) / 3
                      : constraints.maxWidth >= 620
                      ? (constraints.maxWidth - 18) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      _FeatureCard(
                        width: cardWidth,
                        number: '01',
                        icon: Icons.search,
                        title: 'Informasi terkurasi',
                        description: 'Temukan peluang sesuai jenjang dan tujuan pendidikanmu.',
                      ),
                      _FeatureCard(
                        width: cardWidth,
                        number: '02',
                        icon: Icons.trending_up,
                        title: 'Persiapan terpantau',
                        description: 'Kelola dokumen dan progres pendaftaran melalui tracker.',
                      ),
                      _FeatureCard(
                        width: cardWidth,
                        number: '03',
                        icon: Icons.people_outline,
                        title: 'Bimbingan mentor',
                        description:
                            'Diskusikan strategi bersama mentor berpengalaman.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _journeySection(bool wide) => Container(
    key: _journeyKey,
    color: AuthPalette.navy,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 28 : 22,
            vertical: 58,
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 8, child: _JourneyIntro()),
                    const SizedBox(width: 48),
                    Expanded(flex: 10, child: _journeyRows()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _JourneyIntro(),
                    const SizedBox(height: 28),
                    _journeyRows(),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _journeyRows() => const Column(
    children: [
      _JourneyRow(
        number: '01',
        title: 'Jelajahi beasiswa',
        subtitle: 'Cari informasi dan pahami persyaratannya.',
      ),
      _JourneyRow(
        number: '02',
        title: 'Simpan & rencanakan',
        subtitle: 'Bookmark peluang dan pantau persiapanmu.',
      ),
      _JourneyRow(
        number: '03',
        title: 'Belajar bersama mentor',
        subtitle: 'Dapatkan arahan untuk esai dan wawancara.',
      ),
    ],
  );

  Widget _callToAction(bool wide) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 22, vertical: 54),
        child: Container(
          padding: EdgeInsets.all(wide ? 34 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2864F0), Color(0xFF102E63)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AuthPalette.navy.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: wide
              ? Row(
                  children: [
                    const Expanded(child: _CallToActionText()),
                    const SizedBox(width: 20),
                    _callToActionButtons(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CallToActionText(),
                    const SizedBox(height: 22),
                    _callToActionButtons(),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _callToActionButtons() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      FilledButton(
        onPressed: () => _openRegistration('mentee'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AuthPalette.blue,
        ),
        child: const Text('Daftar sebagai Mentee'),
      ),
      OutlinedButton(
        onPressed: () => _openRegistration('mentor'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
        ),
        child: const Text('Daftar sebagai Mentor'),
      ),
    ],
  );

  Widget _footer(bool wide) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFFF8FAFD),
      border: Border(top: BorderSide(color: Color(0xFFE7EDF6))),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 28 : 22,
            vertical: 34,
          ),
          child: Wrap(
            spacing: 70,
            runSpacing: 28,
            children: [
              SizedBox(
                width: wide ? 360 : 280,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BeaskitLogo(),
                    SizedBox(height: 14),
                    Text(
                      'Platform informasi beasiswa dan mentoring untuk '
                      'mahasiswa Indonesia.',
                      style: TextStyle(
                        color: AuthPalette.muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jelajahi',
                    style: TextStyle(
                      color: AuthPalette.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _scrollTo(_journeyKey),
                    child: const Text('Tentang Beaskit'),
                  ),
                  TextButton(
                    onPressed: () => _scrollTo(_featuresKey),
                    child: const Text('Fitur'),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Akun',
                    style: TextStyle(
                      color: AuthPalette.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(onPressed: _openLogin, child: const Text('Masuk')),
                  TextButton(
                    onPressed: _openRoleSelection,
                    child: const Text('Daftar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _header(wide),
                  _hero(wide),
                  _trustStrip(wide),
                  _featureSection(wide),
                  _journeySection(wide),
                  _callToAction(wide),
                  _footer(wide),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 13, color: AuthPalette.blue),
        const SizedBox(width: 7),
      ],
      Text(
        text,
        style: const TextStyle(
          color: AuthPalette.blue,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.15,
        ),
      ),
    ],
  );
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 370,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AuthPalette.blue.withValues(alpha: 0.16)),
          ),
        ),
        Positioned(
          left: 18,
          top: 66,
          child: _FloatingBadge(
            icon: Icons.bookmark_border,
            title: 'Beasiswa',
            subtitle: 'Peluang terkurasi',
          ),
        ),
        Positioned(
          right: 12,
          bottom: 56,
          child: _FloatingBadge(
            icon: Icons.people_outline,
            title: 'Mentor siap',
            subtitle: 'Untuk membimbingmu',
          ),
        ),
        Positioned(
          left: 60,
          right: 42,
          top: 55,
          bottom: 45,
          child: Transform.rotate(
            angle: -0.035,
            child: Container(
              padding: const EdgeInsets.all(27),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF153D88), Color(0xFF3477F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AuthPalette.navy.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Spacer(),
                  Text(
                    'REKOMENDASI UNTUKMU',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Peluang beasiswa\nuntuk masa depanmu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    child: LinearProgressIndicator(
                      value: 0.78,
                      minHeight: 7,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Persiapanmu, satu langkah lebih terarah',
                    style: TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AuthPalette.navy.withValues(alpha: 0.12),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AuthPalette.blue, size: 19),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AuthPalette.navy,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AuthPalette.muted, fontSize: 8),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TrustLabel extends StatelessWidget {
  const _TrustLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF8CA0BF),
      fontWeight: FontWeight.w800,
      fontSize: 12,
      letterSpacing: 0.8,
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.width,
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 190),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AuthPalette.border),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AuthPalette.blue, size: 21),
            ),
            Text(
              number,
              style: const TextStyle(
                color: Color(0xFFB7C8E5),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          title,
          style: const TextStyle(
            color: AuthPalette.navy,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: AuthPalette.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _JourneyIntro extends StatelessWidget {
  const _JourneyIntro();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Eyebrow(text: 'LAYANAN BEASKIT'),
      SizedBox(height: 12),
      Text(
        'Dari mencari hingga\nsiap mendaftar',
        style: TextStyle(
          color: Colors.white,
          fontSize: 34,
          height: 1.12,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 12),
      Text(
        'Setiap fitur dirancang untuk mendukung langkah penting '
        'dalam perjalanan beasiswamu.',
        style: TextStyle(color: Colors.white70, height: 1.55),
      ),
    ],
  );
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 19),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Colors.white24)),
    ),
    child: Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Color(0xFF78A9FF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.white70, size: 17),
      ],
    ),
  );
}

class _CallToActionText extends StatelessWidget {
  const _CallToActionText();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'MULAI HARI INI',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      SizedBox(height: 12),
      Text(
        'Kesempatan terbaik dimulai dari persiapan yang tepat.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 23,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
    ],
  );
}
