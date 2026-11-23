import 'package:flutter/material.dart';

import '../../models/scholarship.dart';
import '../../services/bookmark_service.dart';
import '../../services/tracker_service.dart';
import 'tracker_detail_screen.dart';

class ScholarshipDetailScreen extends StatefulWidget {
  final Scholarship scholarship;

  const ScholarshipDetailScreen({super.key, required this.scholarship});

  @override
  State<ScholarshipDetailScreen> createState() =>
      _ScholarshipDetailScreenState();
}

class _ScholarshipDetailScreenState extends State<ScholarshipDetailScreen> {
  final _trackerService = TrackerService();
  bool _addingToTracker = false;

  Future<void> _addToTracker() async {
    setState(() => _addingToTracker = true);
    try {
      final added = await _trackerService.addToTracker(widget.scholarship);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              added
                  ? 'Ditambahkan ke tracker.'
                  : 'Beasiswa ini sudah ada di tracker.',
            ),
          ),
        );
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => TrackerDetailScreen(
            trackerId: _trackerService.trackerIdFor(widget.scholarship.id),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      final friendly = message.startsWith('Exception: ')
          ? message.substring('Exception: '.length)
          : 'Gagal menambahkan beasiswa ke tracker. Periksa koneksi, lalu coba lagi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendly)),
      );
    } finally {
      if (mounted) setState(() => _addingToTracker = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scholarship;
    final bookmarks = BookmarkService();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Beasiswa')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(s.organizer),
                const SizedBox(height: 16),
                Chip(
                  avatar: const Icon(Icons.event, size: 18),
                  label: Text(s.isClosed
                      ? 'Pendaftaran ditutup (${s.deadlineText})'
                      : 'Tenggat: ${s.deadlineText}'),
                ),
                if (s.isClosed) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tenggat sudah lewat, tetapi beasiswa tetap dapat ditambahkan ke tracker.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                _Section(title: 'Deskripsi', body: s.description),
                _Section(title: 'Persyaratan', body: s.requirements),
                if (s.applicationUrl.isNotEmpty) ...[
                  const Text('Tautan resmi',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  SelectableText(s.applicationUrl),
                  const SizedBox(height: 8),
                  const Text(
                    'Periksa persyaratan dan tenggat di sumber resmi sebelum mendaftar.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StreamBuilder<Set<String>>(
                      stream: bookmarks.watchBookmarkedIds(),
                      builder: (context, snap) {
                        final saved = snap.data?.contains(s.id) ?? false;
                        return FilledButton.icon(
                          icon: Icon(
                              saved ? Icons.bookmark : Icons.bookmark_border),
                          label: Text(saved ? 'Tersimpan' : 'Bookmark'),
                          onPressed: () async {
                            try {
                              await bookmarks.toggle(s.id,
                                  currentlyBookmarked: saved);
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Gagal memperbarui bookmark.')));
                            }
                          },
                        );
                      },
                    ),
                    OutlinedButton(
                      onPressed: _addingToTracker ? null : _addToTracker,
                      child: _addingToTracker
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.checklist),
                                SizedBox(width: 8),
                                Text('Tambahkan ke Tracker'),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(body.isEmpty ? '-' : body),
        ],
      ),
    );
  }
}
