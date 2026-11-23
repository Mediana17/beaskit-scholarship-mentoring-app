import 'package:flutter/material.dart';

import '../../models/tracker.dart';
import '../../services/tracker_service.dart';

class TrackerDetailScreen extends StatefulWidget {
  const TrackerDetailScreen({super.key, required this.trackerId});

  final String trackerId;

  @override
  State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
}

class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
  final _service = TrackerService();
  late final Stream<Tracker?> _trackerStream = _service.watchTracker(
    widget.trackerId,
  );
  late final Stream<List<TrackerDocument>> _documentsStream = _service
      .watchDocuments(widget.trackerId);
  bool _updatingStatus = false;
  final Set<String> _updatingDocuments = {};

  void _showError(Object error) {
    final message = error.toString();
    final friendly = message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : 'Perubahan gagal disimpan. Periksa koneksi, lalu coba lagi.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(friendly)));
  }

  Future<void> _setStatus(PreparationStatus status) async {
    setState(() => _updatingStatus = true);
    try {
      await _service.setStatus(widget.trackerId, status);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _setDocument(TrackerDocument document, bool value) async {
    setState(() => _updatingDocuments.add(document.id));
    try {
      await _service.setDocumentCompleted(document.id, value);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _updatingDocuments.remove(document.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker Beasiswa')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<Tracker?>(
            stream: _trackerStream,
            builder: (context, trackerSnapshot) {
              if (trackerSnapshot.connectionState == ConnectionState.waiting &&
                  !trackerSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (trackerSnapshot.hasError) {
                return const Center(
                  child: Text('Gagal memuat tracker beasiswa.'),
                );
              }
              final tracker = trackerSnapshot.data;
              if (tracker == null) {
                return const Center(child: Text('Tracker tidak ditemukan.'));
              }
              return StreamBuilder<List<TrackerDocument>>(
                stream: _documentsStream,
                builder: (context, documentsSnapshot) {
                  if (documentsSnapshot.hasError) {
                    return const Center(
                      child: Text('Gagal memuat checklist dokumen.'),
                    );
                  }
                  if (documentsSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !documentsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final documents =
                      documentsSnapshot.data ?? <TrackerDocument>[];
                  final withDocuments = tracker.withDocuments(documents);
                  final completed = documents
                      .where((document) => document.isCompleted)
                      .length;
                  final percent = (withDocuments.progress * 100).round();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        tracker.scholarshipTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Tenggat: ${tracker.deadlineText}'),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<PreparationStatus>(
                        initialValue: tracker.preparationStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status persiapan',
                          border: OutlineInputBorder(),
                        ),
                        items: PreparationStatus.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                            )
                            .toList(),
                        onChanged: _updatingStatus
                            ? null
                            : (status) {
                                if (status != null &&
                                    status != tracker.preparationStatus) {
                                  _setStatus(status);
                                }
                              },
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: withDocuments.progress,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percent% • $completed dari ${documents.length} '
                        'dokumen siap',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Checklist dokumen',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (documents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Belum ada dokumen checklist.'),
                        )
                      else
                        ...documents.map(
                          (document) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(document.documentName),
                            value: document.isCompleted,
                            onChanged: _updatingDocuments.contains(document.id)
                                ? null
                                : (value) {
                                    if (value != null) {
                                      _setDocument(document, value);
                                    }
                                  },
                          ),
                        ),
                    ],
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
