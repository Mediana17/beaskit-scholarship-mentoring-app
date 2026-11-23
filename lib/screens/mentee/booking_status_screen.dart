import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../booking_contact_panel.dart';

class BookingStatusScreen extends StatefulWidget {
  const BookingStatusScreen({super.key});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  final _service = BookingService();
  Stream<List<Booking>>? _bookings;
  Timer? _refreshTimer;
  final Set<String> _cancelling = {};

  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      _bookings = _service.watchMenteeBookings(uid);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _expireBookingsOnOpen();
      });
    }
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

  Future<void> _cancel(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan booking?'),
        content: const Text('Booking ini akan dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan Booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling.add(booking.id));
    try {
      await _service.cancelBooking(booking.id);
      if (!mounted) return;
      _showMessage('Booking berhasil dibatalkan.');
    } on BookingException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Booking gagal dibatalkan. Periksa koneksi, lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling.remove(booking.id));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Booking')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _bookings == null
              ? const Center(
                  child: Text('Silakan masuk untuk melihat status booking.'),
                )
              : StreamBuilder<List<Booking>>(
                  stream: _bookings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Gagal memuat status booking. Periksa koneksi Anda.',
                        ),
                      );
                    }
                    final bookings = snapshot.data ?? <Booking>[];
                    if (bookings.isEmpty) {
                      return const Center(
                        child: Text('Belum ada booking mentor.'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final status = booking.displayStatus;
                        final canCancel = booking.canCancel;
                        final cancelling = _cancelling.contains(booking.id);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.mentorName?.trim().isNotEmpty == true
                                      ? booking.mentorName!.trim()
                                      : 'Mentor',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Jadwal: ${_scheduleText(context, booking)}',
                                ),
                                const SizedBox(height: 4),
                                Text('Status: ${booking.statusLabel}'),
                                if (status == BookingStatus.pending)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Sisa ${_minutesLeft(booking)} menit '
                                      'untuk persetujuan',
                                    ),
                                  ),
                                if (status == BookingStatus.rejected &&
                                    booking.rejectionReason?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Alasan penolakan: '
                                      '${booking.rejectionReason}',
                                    ),
                                  ),
                                if (status == BookingStatus.expired)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Booking kedaluwarsa karena tidak '
                                      'diputuskan dalam 30 menit; slot dilepas.',
                                    ),
                                  ),
                                if (status == BookingStatus.confirmed ||
                                    status == BookingStatus.completed)
                                  BookingContactPanel(
                                    service: _service,
                                    bookingId: booking.id,
                                    isMentorView: false,
                                  ),
                                if (canCancel) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: cancelling
                                        ? null
                                        : () => _cancel(booking),
                                    child: cancelling
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Batalkan Booking'),
                                  ),
                                ] else if (booking.status ==
                                        BookingStatus.confirmed &&
                                    status == BookingStatus.confirmed) ...[
                                  const SizedBox(height: 12),
                                  const OutlinedButton(
                                    onPressed: null,
                                    child: Text('Batalkan Booking'),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Booking terkonfirmasi hanya bisa '
                                    'dibatalkan minimal 24 jam sebelum sesi.',
                                  ),
                                ],
                              ],
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
