import 'package:flutter/material.dart';

import 'auth_components.dart';
import 'register_role_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _sendingReset = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.login(email: _email.text, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AuthService.messageFor(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Masukkan email yang valid terlebih dahulu.'),
          ),
        );
      return;
    }

    setState(() => _sendingReset = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Jika akun dengan email $email terdaftar, tautan untuk mengatur ulang password akan dikirim.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AuthService.messageFor(error))));
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF9FBFF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AuthPalette.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AuthPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AuthPalette.blue, width: 1.5),
    ),
  );

  Widget _formCard() => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE7EDF6)),
      boxShadow: [
        BoxShadow(
          color: AuthPalette.navy.withValues(alpha: 0.06),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang kembali',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AuthPalette.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Masuk untuk melanjutkan persiapan beasiswamu.',
            style: TextStyle(color: AuthPalette.muted, height: 1.5),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.mail_outline,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Email wajib diisi'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.password],
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? 'Sembunyikan password'
                    : 'Tampilkan password',
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Password wajib diisi' : null,
            onFieldSubmitted: (_) => _login(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading || _sendingReset ? null : _sendPasswordReset,
              child: _sendingReset
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lupa password?'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _login,
              style: FilledButton.styleFrom(
                backgroundColor: AuthPalette.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Masuk'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text(
                  'Belum punya akun? ',
                  style: TextStyle(color: AuthPalette.muted),
                ),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterRoleScreen(),
                    ),
                  ),
                  child: const Text(
                    'Daftar gratis',
                    style: TextStyle(
                      color: AuthPalette.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.paleBlue,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
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
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: AuthWelcomePanel(
                                title: 'Satu langkah lebih dekat',
                                subtitle:
                                    'Lanjutkan perjalananmu menemukan peluang '
                                    'beasiswa dan mempersiapkan pendaftaran.',
                                points: [
                                  'Informasi beasiswa terkurasi',
                                  'Persiapan pendaftaran lebih terarah',
                                  'Bimbingan dari mentor',
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(child: _formCard()),
                          ],
                        )
                      else ...[
                        const BeaskitLogo(),
                        const SizedBox(height: 20),
                        _formCard(),
                      ],
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
