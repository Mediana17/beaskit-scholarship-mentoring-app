import 'package:flutter/material.dart';

import '../../models/mentor_profile.dart';
import '../../services/mentor_verification_service.dart';
import 'mentor_detail_screen.dart';

class MentorVerificationScreen extends StatelessWidget {
  MentorVerificationScreen({super.key});

  final _service = MentorVerificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Mentor')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<List<MentorProfile>>(
            stream: _service.watchPending(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Gagal memuat daftar mentor.'));
              }
              final mentors = snapshot.data ?? <MentorProfile>[];
              if (mentors.isEmpty) {
                return const Center(
                  child: Text('Tidak ada Mentor yang menunggu verifikasi.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: mentors.length,
                itemBuilder: (context, index) {
                  final mentor = mentors[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        mentor.major.isEmpty
                            ? 'Jurusan belum diisi'
                            : mentor.major,
                      ),
                      subtitle: Text(
                        mentor.university.isEmpty
                            ? 'Universitas belum diisi'
                            : mentor.university,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MentorDetailScreen(uid: mentor.uid),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
