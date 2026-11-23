import 'package:flutter/material.dart';

import '../../models/tracker.dart';
import '../../services/tracker_service.dart';
import 'tracker_detail_screen.dart';

class TrackerListScreen extends StatefulWidget {
  const TrackerListScreen({super.key});

  @override
  State<TrackerListScreen> createState() => _TrackerListScreenState();
}

class _TrackerListScreenState extends State<TrackerListScreen> {
  final _service = TrackerService();
  late final Stream<List<Tracker>> _trackers = _service.watchMyTrackers();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker Beasiswa')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<List<Tracker>>(
            stream: _trackers,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Gagal memuat tracker beasiswa.'),
                );
              }
              final trackers = snapshot.data ?? <Tracker>[];
              if (trackers.isEmpty) {
                return const Center(
                  child: Text('Belum ada beasiswa di tracker.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trackers.length,
                itemBuilder: (context, index) {
                  final tracker = trackers[index];
                  return StreamBuilder<List<TrackerDocument>>(
                    stream: _service.watchDocuments(tracker.id),
                    builder: (context, documentsSnapshot) {
                      final documents = documentsSnapshot.data ??
                          const <TrackerDocument>[];
                      final withDocuments = tracker.withDocuments(documents);
                      final percent =
                          (withDocuments.progress * 100).round();
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            tracker.scholarshipTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tenggat: ${tracker.deadlineText}'),
                                Text(
                                  'Status: ${tracker.preparationStatus.label}',
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: withDocuments.progress,
                                  minHeight: 8,
                                ),
                                const SizedBox(height: 4),
                                Text('$percent%'),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TrackerDetailScreen(trackerId: tracker.id),
                            ),
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
