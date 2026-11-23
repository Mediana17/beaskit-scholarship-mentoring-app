import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'auth_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.role})
    : assert(role == 'mentee' || role == 'mentor');

  final String role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _whatsapp = TextEditingController();
  final _auth = AuthService();
  late final String _role = widget.role;
  bool _loading = false;
  bool _showPassword = false;

  bool get _isMentee => _role == 'mentee';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
        whatsapp: _isMentee ? _whatsapp.text : '',
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal. ${AuthService.messageFor(error)}'),
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    helperText: helperText,
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
            _isMentee ? 'Buat akun Mentee' : 'Buat akun Mentor',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AuthPalette.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Lengkapi informasi berikut untuk memulai.',
            style: TextStyle(color: AuthPalette.muted, height: 1.5),
          ),
          if (!_isMentee) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AuthPalette.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Akun Mentor perlu diverifikasi Admin sebelum dapat mengelola jadwal.',
                      style: TextStyle(
                        color: AuthPalette.navy,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: _inputDecoration(
              label: 'Nama lengkap',
              icon: Icons.person_outline,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama wajib diisi'
                : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.mail_outline,
            ),
            validator: (value) => value == null || !value.contains('@')
                ? 'Masukkan email yang valid'
                : null,
          ),
          if (_isMentee) ...[
            const SizedBox(height: 15),
            TextFormField(
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                label: 'Nomor WhatsApp (opsional)',
                icon: Icons.phone_outlined,
                helperText:
                    'Dibagikan kepada Mentor hanya setelah booking disetujui.',
              ),
            ),
          ],
          const SizedBox(height: 15),
          TextFormField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: _inputDecoration(
              label: 'Password (min. 6 karakter)',
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
            validator: (value) => value == null || value.length < 6
                ? 'Password minimal 6 karakter'
                : null,
            onFieldSubmitted: (_) => _register(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _register,
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
                  : Text(
                      _isMentee
                          ? 'Daftar sebagai Mentee'
                          : 'Daftar sebagai Mentor',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ubah pilihan peran'),
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
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 17),
                          label: const Text('Kembali'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AuthWelcomePanel(
                                title: _isMentee
                                    ? 'Persiapkan langkahmu'
                                    : 'Berbagi pengalaman,'
                                          ' membuka peluang',
                                subtitle: _isMentee
                                    ? 'Simpan peluang beasiswa dan siapkan '
                                          'dokumen pendaftaranmu bersama Beaskit.'
                                    : 'Bantu mahasiswa mempersiapkan diri '
                                          'melalui sesi mentoring yang terarah.',
                                points: _isMentee
                                    ? const [
                                        'Temukan peluang beasiswa',
                                        'Pantau progres persiapan',
                                        'Berdiskusi dengan Mentor',
                                      ]
                                    : const [
                                        'Lengkapi profil Mentor setelah daftar',
                                        'Atur jadwal mentoring',
                                        'Tinjau permintaan sesi',
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
