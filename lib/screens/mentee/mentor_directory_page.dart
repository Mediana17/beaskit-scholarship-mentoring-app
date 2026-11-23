import 'package:flutter/material.dart';

import '../../models/mentor_profile.dart';
import '../../models/mentor_schedule.dart';
import '../../services/booking_service.dart';
import '../../services/mentor_profile_service.dart';
import '../../services/schedule_service.dart';

class MentorDirectoryPage extends StatefulWidget {
  const MentorDirectoryPage({super.key});

  @override
  State<MentorDirectoryPage> createState() => _MentorDirectoryPageState();
}

class _MentorDirectoryPageState extends State<MentorDirectoryPage> {
  final _profiles = MentorProfileService();
  final _bookings = BookingService();
  late final Stream<List<MentorProfile>> _mentors = _profiles
      .watchVerifiedMentors();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _expireBookingsOnOpen();
    });
  }

  Future<void> _expireBookingsOnOpen() async {
    try {
      await _bookings.expireBookings();
    } on BookingException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Status booking gagal diperbarui. Periksa koneksi Anda.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Direktori Mentor')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<List<MentorProfile>>(
            stream: _mentors,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _StateMessage(
                  message: 'Gagal memuat daftar mentor. Periksa koneksi Anda.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final mentors = snapshot.data!;
              if (mentors.isEmpty) {
                return const _StateMessage(
                  message: 'Belum ada mentor terverifikasi.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: mentors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _MentorCard(mentor: mentors[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  _MentorCard({required this.mentor});

  final MentorProfile mentor;
  final _schedules = ScheduleService();
  final _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text(mentor.name[0].toUpperCase()),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mentor.expertise.isEmpty
                            ? 'Keahlian belum ditambahkan'
                            : mentor.expertise,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              mentor.description.isEmpty
                  ? 'Deskripsi belum tersedia.'
                  : mentor.description,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _showProfileAndSchedules(context),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Lihat Profil & Jadwal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfileAndSchedules(BuildContext context) async {
    String? bookingScheduleId;
    String? bookingError;
    final bookingCreated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(mentor.name),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(context).height * 0.65,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Keahlian',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mentor.expertise.isEmpty
                        ? 'Keahlian belum ditambahkan.'
                        : mentor.expertise,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Deskripsi',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mentor.description.isEmpty
                        ? 'Deskripsi belum tersedia.'
                        : mentor.description,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Jadwal tersedia',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<MentorSchedule>>(
                    stream: _schedules.watchAvailableSchedules(mentor.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text(
                          'Jadwal gagal dimuat. Silakan coba lagi.',
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final slots = snapshot.data!
                          .where(
                            (slot) => slot.startTime.isAfter(DateTime.now()),
                          )
                          .toList();
                      if (slots.isEmpty) {
                        return const Text(
                          'Belum ada slot jadwal yang tersedia.',
                        );
                      }
                      return Column(
                        children: slots
                            .map(
                              (slot) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Text(_formatSchedule(context, slot)),
                                    FilledButton.icon(
                                      onPressed: bookingScheduleId == slot.id
                                          ? null
                                          : () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (confirmContext) =>
                                                    AlertDialog(
                                                      title: const Text(
                                                        'Ajukan booking?',
                                                      ),
                                                      content: Text(
                                                        'Ajukan sesi bersama '
                                                        '${mentor.name} pada '
                                                        '${_formatSchedule(context, slot)}?\n\n'
                                                        'Jika disetujui, email Anda '
                                                        'dan nomor WhatsApp Anda '
                                                        '(jika diisi) akan dibagikan '
                                                        'kepada mentor. Nomor WhatsApp '
                                                        'mentor juga akan dibagikan '
                                                        'kepada Anda.',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                confirmContext,
                                                                false,
                                                              ),
                                                          child: const Text(
                                                            'Batal',
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                confirmContext,
                                                                true,
                                                              ),
                                                          child: const Text(
                                                            'Setuju & Ajukan',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                              if (confirmed != true) return;
                                              setDialogState(() {
                                                bookingScheduleId = slot.id;
                                                bookingError = null;
                                              });
                                              try {
                                                await _bookingService
                                                    .createBooking(slot.id);
                                                if (dialogContext.mounted) {
                                                  Navigator.of(dialogContext)
                                                      .pop(true);
                                                }
                                              } on BookingException catch (
                                                error
                                              ) {
                                                if (!dialogContext.mounted) {
                                                  return;
                                                }
                                                ScaffoldMessenger.of(
                                                  dialogContext,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      error.message,
                                                    ),
                                                  ),
                                                );
                                                setDialogState(() {
                                                  bookingScheduleId = null;
                                                  bookingError = error.message;
                                                });
                                              } catch (_) {
                                                if (!dialogContext.mounted) {
                                                  return;
                                                }
                                                const message =
                                                    'Booking gagal diajukan. Periksa koneksi, lalu coba lagi.';
                                                ScaffoldMessenger.of(
                                                  dialogContext,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(message),
                                                  ),
                                                );
                                                setDialogState(() {
                                                  bookingScheduleId = null;
                                                  bookingError = message;
                                                });
                                              }
                                            },
                                      icon: bookingScheduleId == slot.id
                                          ? const SizedBox.square(
                                              dimension: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.event_available,
                                              size: 18,
                                            ),
                                      label: Text(
                                        bookingScheduleId == slot.id
                                            ? 'Mengirim...'
                                            : 'Ajukan Booking',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  if (bookingError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      bookingError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
    if (bookingCreated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking diajukan. Menunggu persetujuan mentor (maks. 30 menit).',
          ),
        ),
      );
    }
  }

  String _formatSchedule(BuildContext context, MentorSchedule slot) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(slot.startTime);
    final start = TimeOfDay.fromDateTime(slot.startTime).format(context);
    final end = TimeOfDay.fromDateTime(slot.endTime).format(context);
    return '$date, $start - $end';
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
