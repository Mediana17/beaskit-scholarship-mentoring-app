import 'package:flutter/material.dart';

import '../../models/scholarship.dart';
import '../../services/bookmark_service.dart';
import '../../services/scholarship_service.dart';
import 'scholarship_detail_screen.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = BookmarkService();
    final scholarships = ScholarshipService();

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmark Saya')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<Set<String>>(
            stream: bookmarks.watchBookmarkedIds(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(child: Text('Gagal memuat bookmark.'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final ids = snap.data!;
              if (ids.isEmpty) {
                return const Center(child: Text('Belum ada beasiswa yang disimpan.'));
              }
              return FutureBuilder<List<Scholarship>>(
                key: ValueKey((ids.toList()..sort()).join(',')),
                future: scholarships.getPublishedByIds(ids),
                builder: (context, fSnap) {
                  if (!fSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = fSnap.data!;
                  if (items.isEmpty) {
                    return const Center(
                        child: Text('Beasiswa yang disimpan sudah tidak tersedia.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final s = items[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(s.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${s.organizer}\n${s.isClosed ? 'Ditutup' : 'Tenggat'}: ${s.deadlineText}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: 'Hapus dari bookmark',
                            icon: const Icon(Icons.bookmark_remove),
                            onPressed: () => bookmarks.toggle(s.id,
                                currentlyBookmarked: true),
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
      ),
    );
  }
}
