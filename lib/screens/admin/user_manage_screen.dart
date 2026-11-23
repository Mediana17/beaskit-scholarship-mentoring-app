import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'mentor_detail_screen.dart';

enum _RoleFilter { all, mentee, mentor, admin }

class UserManageScreen extends StatefulWidget {
  const UserManageScreen({super.key});

  @override
  State<UserManageScreen> createState() => _UserManageScreenState();
}

class _UserManageScreenState extends State<UserManageScreen> {
  final _service = UserService();
  final _search = TextEditingController();
  late final Stream<List<UserModel>> _users = _service.watchAllUsers();
  String _query = '';
  _RoleFilter _filter = _RoleFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _roleLabel(String role) => switch (role) {
    'mentee' => 'Mentee',
    'mentor' => 'Mentor',
    'admin' => 'Admin',
    _ => 'Tidak diketahui',
  };

  String _dateLabel(BuildContext context, DateTime? date) => date == null
      ? '-'
      : MaterialLocalizations.of(context).formatMediumDate(date);

  Future<void> _showDetails(UserModel user) async {
    final openMentor = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detail Pengguna'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Nama', value: user.name),
                _DetailRow(label: 'Email', value: user.email),
                _DetailRow(label: 'Role', value: _roleLabel(user.role)),
                _DetailRow(
                  label: 'WhatsApp',
                  value: user.whatsapp.trim().isEmpty ? '-' : user.whatsapp,
                ),
                _DetailRow(
                  label: 'Tanggal daftar',
                  value: _dateLabel(context, user.createdAt),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tutup'),
          ),
          if (user.role == 'mentor')
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lihat profil & verifikasi'),
            ),
        ],
      ),
    );

    if (openMentor == true && mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => MentorDetailScreen(uid: user.uid)),
      );
    }
  }

  List<UserModel> _visibleUsers(List<UserModel> users) {
    return users.where((user) {
      if (_filter != _RoleFilter.all && user.role != _filter.name) {
        return false;
      }
      if (_query.isEmpty) return true;
      return user.name.toLowerCase().contains(_query) ||
          user.email.toLowerCase().contains(_query);
    }).toList();
  }

  Widget _roleSummary(List<UserModel> users) {
    final mentees = users.where((user) => user.role == 'mentee').length;
    final mentors = users.where((user) => user.role == 'mentor').length;
    final admins = users.where((user) => user.role == 'admin').length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(label: 'Total: ${users.length}'),
        _SummaryChip(label: 'Mentee: $mentees'),
        _SummaryChip(label: 'Mentor: $mentors'),
        _SummaryChip(label: 'Admin: $admins'),
      ],
    );
  }

  Widget _userList(List<UserModel> users) {
    final filteredUsers = _visibleUsers(users);
    if (filteredUsers.isEmpty) {
      return const Center(child: Text('Pengguna tidak ditemukan.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: filteredUsers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return Card(
          child: ListTile(
            title: Text(
              user.name.isEmpty ? '-' : user.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${user.email}\n'
                'Role: ${_roleLabel(user.role)}\n'
                'Tanggal daftar: ${_dateLabel(context, user.createdAt)}',
              ),
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showDetails(user),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengguna')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau email',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      setState(() => _query = value.toLowerCase().trim()),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<_RoleFilter>(
                    segments: const [
                      ButtonSegment(
                        value: _RoleFilter.all,
                        label: Text('Semua'),
                      ),
                      ButtonSegment(
                        value: _RoleFilter.mentee,
                        label: Text('Mentee'),
                      ),
                      ButtonSegment(
                        value: _RoleFilter.mentor,
                        label: Text('Mentor'),
                      ),
                      ButtonSegment(
                        value: _RoleFilter.admin,
                        label: Text('Admin'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (selection) =>
                        setState(() => _filter = selection.first),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<UserModel>>(
                    stream: _users,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(_errorMessage(snapshot.error)),
                        );
                      }
                      final users = snapshot.data ?? <UserModel>[];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _roleSummary(users),
                          const SizedBox(height: 8),
                          Expanded(child: _userList(users)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return 'Daftar pengguna gagal dimuat. Periksa koneksi Anda.';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: SelectableText(value.isEmpty ? '-' : value)),
      ],
    ),
  );
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}
