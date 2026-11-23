import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../booking_contact_panel.dart';

class MentorBookingScreen extends StatefulWidget {
  const MentorBookingScreen({super.key, required this.mentorUid});

  final String mentorUid;

  @override
  State<MentorBookingScreen> createState() => _MentorBookingScreenState();
}

class _MentorBookingScreenState extends State<MentorBookingScreen> {
  final _service = BookingService();
  late final Stream<List<Booking>> _bookings = _service.watchMentorBookings(
    widget.mentorUid,
  );
  final Set<String> _processing = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _expireBookingsOnOpen();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _expireBookingsOnOpen() async {
    try {
      await _service.expireBookings();
    } on BookingException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Status booking gagal diperbarui. Periksa koneksi Anda.');
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  int _activeMenteeCount(List<Booking> bookings) => bookings
      .where((booking) => booking.status == BookingStatus.confirmed)
      .map((booking) => booking.menteeUserId)
      .toSet()
      .length;

  Future<bool> _confirmDecision(Booking booking, bool approve) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(approve ? 'Setujui booking?' : 'Tolak booking?'),
            content: Text(
              approve
                  ? 'Setujui permintaan sesi dari ${_menteeName(booking)}?'
                  : 'Tolak permintaan sesi dari ${_menteeName(booking)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(approve ? 'Setujui' : 'Tolak'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _decide(Booking booking, {required bool approve}) async {
    if (!await _confirmDecision(booking, approve)) return;
    setState(() => _processing.add(booking.id));
    try {
      final result = await _service.decideBooking(booking.id, approve: approve);
      if (!mounted) return;
      final message = switch (result.status) {
        'expired' => 'Booking sudah kedaluwarsa.',
        'rejected' when result.reason != null => result.reason!,
        'rejected' => 'Booking ditolak.',
        'confirmed' => 'Booking berhasil disetujui.',
        _ => 'Status booking berhasil diperbarui.',
      };
      _showMessage(message);
    } on BookingException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Booking gagal diperbarui. Periksa koneksi, lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(booking.id));
    }
  }

  Future<void> _markCompleted(Booking booking) async {
    setState(() => _processing.add(booking.id));
    try {
      await _service.markCompleted(booking.id);
      if (mounted) _showMessage('Sesi berhasil ditandai selesai.');
    } on BookingException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Status sesi gagal diperbarui. Periksa koneksi, lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(booking.id));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _menteeName(Booking booking) =>
      booking.menteeName?.trim().isNotEmpty == true
      ? booking.menteeName!.trim()
      : 'Mentee';

  String _scheduleText(BuildContext context, Booking booking) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(booking.startTime);
    final start = TimeOfDay.fromDateTime(booking.startTime).format(context);
    final end = TimeOfDay.fromDateTime(booking.endTime).format(context);
    return '$date, $start - $end';
  }

  int _minutesLeft(Booking booking) {
    final seconds = booking.expiresAt.difference(DateTime.now()).inSeconds;
    return (seconds / 60).ceil().clamp(0, 30);
  }

  Widget _bookingList(BuildContext context, List<Booking> bookings, int tab) {
    final items = bookings.where((booking) {
      switch (tab) {
        case 0:
          return booking.displayStatus == BookingStatus.pending;
        case 1:
          return booking.displayStatus == BookingStatus.confirmed;
        default:
          return const {
            BookingStatus.completed,
            BookingStatus.rejected,
            BookingStatus.cancelled,
            BookingStatus.expired,
          }.contains(booking.displayStatus);
      }
    }).toList();
    if (items.isEmpty) {
      return Center(
        child: Text(switch (tab) {
          0 => 'Tidak ada booking yang menunggu.',
          1 => 'Belum ada sesi yang dikonfirmasi.',
          _ => 'Belum ada riwayat booking.',
        }),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final booking = items[index];
        final status = booking.displayStatus;
        final processing = _processing.contains(booking.id);
        final canComplete =
            status == BookingStatus.confirmed &&
            !booking.endTime.isAfter(DateTime.now());
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _menteeName(booking),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Jadwal: ${_scheduleText(context, booking)}'),
                const SizedBox(height: 4),
                Text('Status: ${booking.statusLabel}'),
                if (status == BookingStatus.pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Sisa ${_minutesLeft(booking)} menit'),
                  ),
                if (status == BookingStatus.rejected &&
                    booking.rejectionReason?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Alasan: ${booking.rejectionReason}'),
                  ),
                if (status == BookingStatus.confirmed ||
                    status == BookingStatus.completed)
                  BookingContactPanel(
                    service: _service,
                    bookingId: booking.id,
                    isMentorView: true,
                  ),
                if (tab == 0 && status == BookingStatus.pending) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: processing
                            ? null
                            : () => _decide(booking, approve: true),
                        child: Text(processing ? 'Memproses...' : 'Setujui'),
                      ),
                      OutlinedButton(
                        onPressed: processing
                            ? null
                            : () => _decide(booking, approve: false),
                        child: const Text('Tolak'),
                      ),
                    ],
                  ),
                ],
                if (tab == 1) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: !canComplete || processing
                        ? null
                        : () => _markCompleted(booking),
                    child: Text(processing ? 'Memproses...' : 'Tandai Selesai'),
                  ),
                  if (!canComplete && !processing)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Tombol aktif setelah sesi berakhir.'),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Mentor'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Menunggu'),
              Tab(text: 'Dikonfirmasi'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: StreamBuilder<List<Booking>>(
              stream: _bookings,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Gagal memuat booking. Periksa koneksi Anda.'),
                  );
                }
                final bookings = snapshot.data ?? <Booking>[];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mentee aktif: ${_activeMenteeCount(bookings)}/3',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _bookingList(context, bookings, 0),
                          _bookingList(context, bookings, 1),
                          _bookingList(context, bookings, 2),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
