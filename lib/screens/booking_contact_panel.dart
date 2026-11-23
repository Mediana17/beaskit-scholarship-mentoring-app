import 'package:flutter/material.dart';

import '../models/booking_contact.dart';
import '../services/booking_service.dart';

class BookingContactPanel extends StatefulWidget {
  const BookingContactPanel({
    super.key,
    required this.service,
    required this.bookingId,
    required this.isMentorView,
  });

  final BookingService service;
  final String bookingId;
  final bool isMentorView;

  @override
  State<BookingContactPanel> createState() => _BookingContactPanelState();
}

class _BookingContactPanelState extends State<BookingContactPanel> {
  bool _syncing = false;
  bool _mentorSyncStarted = false;
  String? _syncError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncContact());
  }

  @override
  void didUpdateWidget(covariant BookingContactPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookingId != widget.bookingId ||
        oldWidget.isMentorView != widget.isMentorView) {
      _mentorSyncStarted = false;
      _syncError = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncContact());
    }
  }

  Future<void> _syncContact() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncError = null;
    });
    try {
      await widget.service.ensureConfirmedBookingContact(
        widget.bookingId,
        mentorView: widget.isMentorView,
      );
    } on BookingException catch (error) {
      if (mounted) setState(() => _syncError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _syncError = 'Kontak gagal diperbarui. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BookingContact?>(
      stream: widget.service.watchBookingContact(widget.bookingId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Informasi kontak gagal dimuat.');
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        final contact = snapshot.data;
        if (contact == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isMentorView
                    ? 'Menunggu Mentee membuka Status Booking untuk membagikan kontak.'
                    : 'Menyiapkan kontak yang dibagikan untuk sesi ini.',
              ),
              if (_syncError != null)
                Text(
                  _syncError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              TextButton(
                onPressed: _syncing ? null : _syncContact,
                child: Text(_syncing ? 'Memuat kontak...' : 'Coba muat kontak'),
              ),
            ],
          );
        }
        if (widget.isMentorView &&
            contact.mentorWhatsApp.isEmpty &&
            !_mentorSyncStarted) {
          _mentorSyncStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _syncContact());
        }
        final title = widget.isMentorView ? 'Kontak Mentee' : 'Kontak Mentor';
        final email = widget.isMentorView ? contact.menteeEmail : '';
        final whatsapp = widget.isMentorView
            ? contact.menteeWhatsApp
            : contact.mentorWhatsApp;

        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Email'),
                  SelectableText(email),
                ],
                const SizedBox(height: 8),
                const Text('WhatsApp'),
                SelectableText(whatsapp.isEmpty ? 'Belum dibagikan' : whatsapp),
              ],
            ),
          ),
        );
      },
    );
  }
}
