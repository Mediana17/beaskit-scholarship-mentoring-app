import 'package:flutter/material.dart';

import '../../models/scholarship.dart';
import '../../services/bookmark_service.dart';
import '../../services/scholarship_service.dart';
import 'scholarship_detail_screen.dart';

class ScholarshipListScreen extends StatefulWidget {
  const ScholarshipListScreen({super.key});

  @override
  State<ScholarshipListScreen> createState() => _ScholarshipListScreenState();
}

class _ScholarshipListScreenState extends State<ScholarshipListScreen> {
  final _search = TextEditingController();
  final _scholarships = ScholarshipService();
  final _bookmarks = BookmarkService();
  late final Stream<List<Scholarship>> _listStream = _scholarships.watchPublished();
  late final Stream<Set<String>> _bookmarkStream = _bookmarks.watchBookmarkedIds();
  String _query = '';
  bool _onlyOpen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(String id, bool current) async {
    try {
      await _bookmarks.toggle(id, currentlyBookmarked: current);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui bookmark.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Beasiswa')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        hintText: 'Cari judul, penyelenggara, atau deskripsi',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          setState(() => _query = v.toLowerCase().trim()),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        label: const Text('Hanya yang masih dibuka'),
                        selected: _onlyOpen,
                        onSelected: (v) => setState(() => _onlyOpen = v),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Scholarship>>(
                  stream: _listStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const Center(
                          child: Text('Gagal memuat data beasiswa.'));
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snap.data!.where((s) {
                      if (_onlyOpen && s.isClosed) return false;
                      if (_query.isEmpty) return true;
                      return s.title.toLowerCase().contains(_query) ||
                          s.organizer.toLowerCase().contains(_query) ||
                          s.description.toLowerCase().contains(_query);
                    }).toList();
                    if (items.isEmpty) {
                      return const Center(child: Text('Beasiswa tidak ditemukan.'));
                    }
                    return StreamBuilder<Set<String>>(
                      stream: _bookmarkStream,
                      builder: (context, bSnap) {
                        final saved = bSnap.data ?? <String>{};
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final s = items[i];
                            final isSaved = saved.contains(s.id);
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(s.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(s.organizer),
                                    const SizedBox(height: 4),
                                    Text(s.isClosed
                                        ? 'Ditutup: ${s.deadlineText}'
                                        : 'Tenggat: ${s.deadlineText}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  tooltip: isSaved
                                      ? 'Hapus dari bookmark'
                                      : 'Simpan ke bookmark',
                                  icon: Icon(isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border),
                                  onPressed: () => _toggle(s.id, isSaved),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ScholarshipDetailScreen(scholarship: s)),
                                ),
                              ),
                            );
                          },
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
