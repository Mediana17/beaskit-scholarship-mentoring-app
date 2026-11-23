import 'package:flutter/material.dart';

class AuthPalette {
  static const navy = Color(0xFF102E63);
  static const blue = Color(0xFF2864F0);
  static const paleBlue = Color(0xFFF3F7FF);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFDCE6F5);
}

class BeaskitLogo extends StatelessWidget {
  const BeaskitLogo({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2871FF), Color(0xFF53A0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: AuthPalette.blue.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_stories_outlined,
          color: Colors.white,
          size: 23,
        ),
      ),
      const SizedBox(width: 11),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Beaskit',
            style: TextStyle(
              color: onDark ? Colors.white : AuthPalette.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'BEASISWA KITA',
            style: TextStyle(
              color: onDark ? Colors.white70 : AuthPalette.muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.15,
            ),
          ),
        ],
      ),
    ],
  );
}

class AuthWelcomePanel extends StatelessWidget {
  const AuthWelcomePanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  final String title;
  final String subtitle;
  final List<String> points;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(34),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF2864F0), Color(0xFF102E63)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: AuthPalette.navy.withValues(alpha: 0.18),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BeaskitLogo(onDark: true),
        const SizedBox(height: 52),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, height: 1.6),
        ),
        const SizedBox(height: 24),
        ...points.map(
          (point) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF8FC2FF),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
