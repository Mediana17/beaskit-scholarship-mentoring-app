import 'package:flutter/material.dart';

import '../../models/scholarship.dart';
import '../../services/scholarship_admin_service.dart';
import 'scholarship_form_screen.dart';

enum _ScholarshipFilter { all, published, archived }

class ScholarshipManageScreen extends StatefulWidget {
  const ScholarshipManageScreen({super.key});

  @override
  State<ScholarshipManageScreen> createState() =>
      _ScholarshipManageScreenState();
}

class _ScholarshipManageScreenState extends State<ScholarshipManageScreen> {
  final _service = ScholarshipAdminService();
  final _search = TextEditingController();
  late final Stream<List<Scholarship>> _stream = _service.watchAll();
  String _query = '';
  _ScholarshipFilter _filter = _ScholarshipFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm([Scholarship? scholarship]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ScholarshipFormScreen(scholarship: scholarship),
      ),
    );
  }

  Future<void> _archive(Scholarship scholarship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arsipkan beasiswa?'),
        content: const Text(
          'Beasiswa akan disembunyikan dari Mentee, bookmark dan tracker tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.archive(scholarship.id);
      if (!mounted) return;
      _showMessage('Beasiswa berhasil diarsipkan.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _restore(Scholarship scholarship) async {
    try {
      await _service.restore(scholarship.id);
      if (!mounted) return;
      _showMessage('Beasiswa berhasil dipulihkan.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : 'Terjadi kesalahan. Silakan coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengelolaan Beasiswa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Beasiswa'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        hintText: 'Cari judul atau penyelenggara',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(
                        () => _query = value.toLowerCase().trim(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Semua'),
                          selected: _filter == _ScholarshipFilter.all,
                          onSelected: (_) => setState(
                            () => _filter = _ScholarshipFilter.all,
                          ),
                        ),
                        FilterChip(
                          label: const Text('Dipublikasikan'),
                          selected: _filter == _ScholarshipFilter.published,
                          onSelected: (_) => setState(
                            () => _filter = _ScholarshipFilter.published,
                          ),
                        ),
                        FilterChip(
                          label: const Text('Diarsipkan'),
                          selected: _filter == _ScholarshipFilter.archived,
                          onSelected: (_) => setState(
                            () => _filter = _ScholarshipFilter.archived,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Scholarship>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Gagal memuat daftar beasiswa.'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final scholarships = (snapshot.data ?? <Scholarship>[])
                        .where((scholarship) {
                      if (_filter == _ScholarshipFilter.published &&
                          scholarship.status != 'published') {
                        return false;
                      }
                      if (_filter == _ScholarshipFilter.archived &&
                          scholarship.status != 'archived') {
                        return false;
                      }
                      if (_query.isEmpty) return true;
                      return scholarship.title.toLowerCase().contains(_query) ||
                          scholarship.organizer.toLowerCase().contains(_query);
                    }).toList();
                    if (scholarships.isEmpty) {
                      return const Center(child: Text('Belum ada beasiswa.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: scholarships.length,
                      itemBuilder: (context, index) {
                        final scholarship = scholarships[index];
                        final isPublished = scholarship.status == 'published';
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              scholarship.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${scholarship.organizer}\n'
                                'Tenggat: ${scholarship.deadlineText}\n'
                                'Status: ${isPublished ? 'Dipublikasikan' : 'Diarsipkan'}',
                              ),
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Ubah beasiswa',
                                  onPressed: () => _openForm(scholarship),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: isPublished
                                      ? 'Arsipkan beasiswa'
                                      : 'Pulihkan beasiswa',
                                  onPressed: () => isPublished
                                      ? _archive(scholarship)
                                      : _restore(scholarship),
                                  icon: Icon(
                                    isPublished
                                        ? Icons.archive_outlined
                                        : Icons.unarchive_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
