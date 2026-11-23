import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, rejected, cancelled, completed, expired }

BookingStatus _parseStatus(String? s) => BookingStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => BookingStatus.pending,
    );

class Booking {
  final String id;
  final String menteeUserId;
  final String mentorUserId;
  final String scheduleId;
  final BookingStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime requestedAt;
  final DateTime expiresAt;
  final String? rejectionReason;
  final String? menteeName;
  final String? mentorName;

  const Booking({
    required this.id,
    required this.menteeUserId,
    required this.mentorUserId,
    required this.scheduleId,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.requestedAt,
    required this.expiresAt,
    this.rejectionReason,
    this.menteeName,
    this.mentorName,
  });

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime ts(String k) => (d[k] as Timestamp).toDate();
    return Booking(
      id: doc.id,
      menteeUserId: d['mentee_user_id'] as String,
      mentorUserId: d['mentor_user_id'] as String,
      scheduleId: d['schedule_id'] as String,
      status: _parseStatus(d['booking_status'] as String?),
      startTime: ts('start_time'),
      endTime: ts('end_time'),
      requestedAt: ts('requested_at'),
      expiresAt: ts('expires_at'),
      rejectionReason: d['rejection_reason'] as String?,
      menteeName: d['mentee_name'] as String?,
      mentorName: d['mentor_name'] as String?,
    );
  }

  /// Pending yang sudah lewat 30 menit tapi belum sempat diproses scheduler
  /// (maks. ~1 menit) tetap ditampilkan sebagai Expired.
  BookingStatus get displayStatus =>
      status == BookingStatus.pending && expiresAt.isBefore(DateTime.now())
          ? BookingStatus.expired
          : status;

  /// Label teks (tidak hanya warna) sesuai kebutuhan aksesibilitas.
  String get statusLabel => switch (displayStatus) {
        BookingStatus.pending => 'Menunggu persetujuan',
        BookingStatus.confirmed => 'Dikonfirmasi',
        BookingStatus.rejected => 'Ditolak',
        BookingStatus.cancelled => 'Dibatalkan',
        BookingStatus.completed => 'Selesai',
        BookingStatus.expired => 'Kedaluwarsa',
      };

  bool get canCancel =>
      displayStatus == BookingStatus.pending ||
      (displayStatus == BookingStatus.confirmed &&
          startTime.difference(DateTime.now()).inHours >= 24);
}
