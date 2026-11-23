import 'package:flutter/material.dart';

import '../../services/mentor_profile_service.dart';

class MentorProfileScreen extends StatefulWidget {
  const MentorProfileScreen({super.key});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _experienceController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _linkedinController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  final _profileService = MentorProfileService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Mengambil profil mentor yang sudah tersimpan
  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile(
        _profileService.currentUserId,
      );

      if (profile != null) {
        _universityController.text = profile.university;
        _majorController.text = profile.major;
        _experienceController.text = profile.experience;
        _expertiseController.text = profile.expertise;
        _descriptionController.text = profile.description;
        _phoneController.text = profile.phone;
        _emailController.text = profile.email.isEmpty
            ? _profileService.currentEmail ?? ''
            : profile.email;
        _linkedinController.text = profile.linkedin;
      } else {
        _emailController.text = _profileService.currentEmail ?? '';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().startsWith('Exception: ')
                  ? error.toString().substring('Exception: '.length)
                  : 'Profil mentor gagal dimuat. Periksa koneksi Anda.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Menyimpan profil mentor ke Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.saveProfile(
        university: _universityController.text,
        major: _majorController.text,
        experience: _experienceController.text,
        expertise: _expertiseController.text,
        description: _descriptionController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        linkedin: _linkedinController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mentor berhasil disimpan!')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      final message = error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.startsWith('Exception: ')
                ? message.substring('Exception: '.length)
                : 'Profil gagal disimpan. Periksa koneksi Anda.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _universityController.dispose();
    _majorController.dispose();
    _experienceController.dispose();
    _expertiseController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Mentor')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Lengkapi Profil Mentor',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Informasi ini akan digunakan Admin '
                          'untuk proses verifikasi mentor.',
                        ),

                        const SizedBox(height: 24),

                        // Universitas
                        TextFormField(
                          controller: _universityController,
                          decoration: const InputDecoration(
                            labelText: 'Universitas',
                            hintText: 'Contoh: Universitas Indonesia',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Universitas wajib diisi.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Jurusan
                        TextFormField(
                          controller: _majorController,
                          decoration: const InputDecoration(
                            labelText: 'Jurusan',
                            hintText: 'Contoh: Teknik Informatika',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Jurusan wajib diisi.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Pengalaman
                        TextFormField(
                          controller: _experienceController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Pengalaman',
                            hintText:
                                'Ceritakan pengalaman organisasi, '
                                'akademik, atau mentoring.',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Pengalaman wajib diisi.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _expertiseController,
                          decoration: const InputDecoration(
                            labelText: 'Bidang keahlian',
                            hintText: 'Contoh: Beasiswa luar negeri',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            hintText:
                                'Ceritakan pengalaman dan cara mentoring Anda.',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Kontak Mentor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp',
                            hintText: 'Contoh: 081234567890',
                            helperText: 'Dibagikan kepada Mentee hanya setelah booking disetujui.',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nomor telepon wajib diisi.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Kontak',
                            hintText: 'Contoh: nama@email.com',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Email wajib diisi.';
                            }
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)) {
                              return 'Format email tidak valid.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _linkedinController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'LinkedIn',
                            hintText: 'https://www.linkedin.com/in/username',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Profil LinkedIn wajib diisi.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const CircularProgressIndicator()
                              : const Text('Simpan Profil'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
