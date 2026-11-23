import 'package:flutter/material.dart';

import '../../models/mentor_schedule.dart';
import '../../services/schedule_service.dart';

class ScheduleManageScreen extends StatefulWidget {
  const ScheduleManageScreen({super.key, required this.mentorUid});

  final String mentorUid;

  @override
  State<ScheduleManageScreen> createState() => _ScheduleManageScreenState();
}

class _ScheduleManageScreenState extends State<ScheduleManageScreen> {
  final _service = ScheduleService();
  late final Stream<List<MentorSchedule>> _schedules =
      _service.watchMySchedules(widget.mentorUid);
  bool _isAdding = false;
  final Set<String> _updatingSlots = {};

  void _showError(Object error) {
    final message = error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.startsWith('Exception: ')
              ? message.substring('Exception: '.length)
              : 'Jadwal gagal diperbarui. Silakan coba lagi.',
        ),
      ),
    );
  }

  Future<void> _addSlot() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(now),
      firstDate: DateUtils.dateOnly(now),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Pilih tanggal jadwal',
    );
    if (date == null || !mounted) return;

    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      helpText: 'Pilih waktu mulai',
    );
    if (startTime == null || !mounted) return;

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start.add(const Duration(hours: 1))),
      helpText: 'Pilih waktu selesai',
    );
    if (endTime == null || !mounted) return;

    final end = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );
    setState(() => _isAdding = true);
    try {
      await _service.addSlot(start, end);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _setActive(MentorSchedule schedule, bool active) async {
    setState(() => _updatingSlots.add(schedule.id));
    try {
      if (active) {
        await _service.activate(schedule.id);
      } else {
        await _service.deactivate(schedule.id);
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _updatingSlots.remove(schedule.id));
    }
  }

  String _formatDateTime(MentorSchedule schedule) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(schedule.startTime);
    final start = TimeOfDay.fromDateTime(schedule.startTime).format(context);
    final end = TimeOfDay.fromDateTime(schedule.endTime).format(context);
    return '$date, $start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Jadwal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAdding ? null : _addSlot,
        icon: _isAdding
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Tambah Slot'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<List<MentorSchedule>>(
            stream: _schedules,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Gagal memuat jadwal. Periksa koneksi Anda.'),
                );
              }
              final schedules = snapshot.data ?? <MentorSchedule>[];
              if (schedules.isEmpty) {
                return const Center(child: Text('Belum ada slot jadwal.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  final isBooked = schedule.isBooked;
                  final isAvailable =
                      schedule.availabilityStatus == 'available';
                  final isInactive =
                      schedule.availabilityStatus == 'inactive';
                  final isPast = !schedule.startTime.isAfter(DateTime.now());
                  final updating = _updatingSlots.contains(schedule.id);
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(_formatDateTime(schedule)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${schedule.statusLabel}'),
                            if (isBooked)
                              const Text('Ada booking pada slot ini.'),
                            if (isInactive && isPast)
                              const Text(
                                'Slot yang sudah dimulai tidak dapat diaktifkan.',
                              ),
                          ],
                        ),
                      ),
                      isThreeLine: isBooked || (isInactive && isPast),
                      trailing: isBooked
                          ? const SizedBox(
                              width: 120,
                              child: Text(
                                'Ada booking pada slot ini',
                                textAlign: TextAlign.end,
                              ),
                            )
                          : TextButton(
                              onPressed: updating || (isInactive && isPast)
                                  ? null
                                  : () => _setActive(schedule, isInactive),
                              child: updating
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      isAvailable
                                          ? 'Nonaktifkan'
                                          : 'Aktifkan',
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
