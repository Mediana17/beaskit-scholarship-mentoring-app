import 'package:flutter/material.dart';

import '../../models/mentor_profile.dart';
import '../../services/mentor_verification_service.dart';

class MentorDetailScreen extends StatefulWidget {
  final String uid;

  const MentorDetailScreen({super.key, required this.uid});

  @override
  State<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen> {
  final _service = MentorVerificationService();
  late final Future<MentorProfile?> _mentor = _service.getMentorForAdmin(
    widget.uid,
  );
  bool _isSaving = false;

  Future<void> _approveMentor() async {
    setState(() => _isSaving = true);
    try {
      await _service.approveMentor(widget.uid);
      if (!mounted) return;
      _showMessage('Mentor berhasil disetujui.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _rejectMentor() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Mentor'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alasan penolakan',
            hintText: 'Masukkan alasan penolakan mentor',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(dialogContext, text);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await _service.rejectMentor(widget.uid, reason);
      if (!mounted) return;
      _showMessage('Mentor berhasil ditolak.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return 'Data mentor gagal diproses. Silakan coba lagi.';
  }

  String _statusLabel(String status) => switch (status) {
    'verified' => 'Terverifikasi',
    'rejected' => 'Ditolak',
    _ => 'Menunggu verifikasi',
  };

  Widget _detail(MentorProfile mentor) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
      const SizedBox(height: 24),
      Text(
        mentor.name,
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Text('Informasi Mentor', style: Theme.of(context).textTheme.titleLarge),
      ListTile(
        title: const Text('Universitas'),
        subtitle: Text(_value(mentor.university)),
      ),
      ListTile(
        title: const Text('Jurusan'),
        subtitle: Text(_value(mentor.major)),
      ),
      ListTile(
        title: const Text('Pengalaman'),
        subtitle: Text(_value(mentor.experience)),
      ),
      ListTile(
        title: const Text('Keahlian'),
        subtitle: Text(_value(mentor.expertise)),
      ),
      ListTile(
        title: const Text('Deskripsi'),
        subtitle: Text(_value(mentor.description)),
      ),
      const SizedBox(height: 8),
      Text('Kontak Mentor', style: Theme.of(context).textTheme.titleLarge),
      ListTile(
        leading: const Icon(Icons.phone),
        title: const Text('Nomor Telepon'),
        subtitle: Text(_value(mentor.phone)),
      ),
      ListTile(
        leading: const Icon(Icons.email),
        title: const Text('Email'),
        subtitle: Text(_value(mentor.email)),
      ),
      ListTile(
        leading: const Icon(Icons.link),
        title: const Text('LinkedIn'),
        subtitle: Text(_value(mentor.linkedin)),
      ),
      ListTile(
        title: const Text('Status Verifikasi'),
        subtitle: Text(_statusLabel(mentor.verificationStatus)),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _isSaving ? null : _approveMentor,
        child: const Text('Setujui Mentor'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _isSaving ? null : _rejectMentor,
        child: const Text('Tolak Mentor'),
      ),
    ],
  );

  String _value(String value) => value.trim().isEmpty ? '-' : value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Mentor')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder<MentorProfile?>(
            future: _mentor,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Profil mentor gagal dimuat. Periksa koneksi Anda.',
                  ),
                );
              }
              final mentor = snapshot.data;
              if (mentor == null) {
                return const Center(
                  child: Text('Profil mentor tidak ditemukan.'),
                );
              }
              return _detail(mentor);
            },
          ),
        ),
      ),
    );
  }
}
