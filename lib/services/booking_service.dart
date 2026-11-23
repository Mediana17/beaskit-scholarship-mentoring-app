import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking.dart';
import '../models/booking_contact.dart';

/// Pesan galat yang aman ditampilkan langsung ke pengguna.
class BookingException implements Exception {
  const BookingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DecisionResult {
  const DecisionResult(this.status, this.reason);

  final String status;
  final String? reason;
}

class BookingService {
  BookingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _pendingMinutes = 30;
  static const _maxActiveMentees = 3;
  static const _autoRejectReason = 'Kapasitas penuh atau jadwal bentrok';

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw const BookingException('Silakan masuk terlebih dahulu.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  Future<String> createBooking(String scheduleId) async {
    if (scheduleId.trim().isEmpty) {
      throw const BookingException('Jadwal tidak valid.');
    }
    final menteeId = _uid;
    final bookingRef = _bookings.doc();
    final bookingContactRef = _db
        .collection('booking_contacts')
        .doc(bookingRef.id);
    final scheduleRef = _db.collection('mentor_schedules').doc(scheduleId);
    final menteeRef = _db.collection('users').doc(menteeId);
    final menteeEmail = _auth.currentUser?.email?.trim() ?? '';
    if (menteeEmail.isEmpty) {
      throw const BookingException(
        'Email akun tidak tersedia. Perbarui email akun sebelum mengajukan booking.',
      );
    }

    try {
      final schedulePreview = await scheduleRef.get();
      if (!schedulePreview.exists) {
        throw const BookingException('Jadwal tidak ditemukan.');
      }
      final previewMentorId = schedulePreview.data()?['mentor_user_id'];
      if (previewMentorId is! String || previewMentorId.isEmpty) {
        throw const BookingException('Data mentor pada jadwal tidak valid.');
      }
      final scheduleListSnapshot = await _db
          .collection('mentor_schedules')
          .where('mentor_user_id', isEqualTo: previewMentorId)
          .limit(200)
          .get();
      await _db.runTransaction((transaction) async {
        final scheduleSnapshot = await transaction.get(scheduleRef);
        final menteeSnapshot = await transaction.get(menteeRef);
        if (!scheduleSnapshot.exists) {
          throw const BookingException('Jadwal tidak ditemukan.');
        }
        final schedule = scheduleSnapshot.data()!;
        if (!menteeSnapshot.exists ||
            menteeSnapshot.data()?['role'] != 'mentee') {
          throw const BookingException(
            'Hanya Mentee yang dapat mengajukan booking.',
          );
        }
        final mentorId = schedule['mentor_user_id'];
        if (mentorId is! String ||
            mentorId.isEmpty ||
            mentorId != previewMentorId) {
          throw const BookingException('Data mentor pada jadwal tidak valid.');
        }
        final mentorRef = _db
            .collection('mentor_public_profiles')
            .doc(mentorId);
        final mentorSnapshot = await transaction.get(mentorRef);
        if (!mentorSnapshot.exists ||
            mentorSnapshot.data()?['verification_status'] != 'verified') {
          throw const BookingException('Mentor belum terverifikasi.');
        }
        final now = Timestamp.now();
        final startTime = schedule['start_time'];
        final endTime = schedule['end_time'];
        if (schedule['availability_status'] != 'available' ||
            startTime is! Timestamp ||
            endTime is! Timestamp ||
            !startTime.toDate().isAfter(now.toDate())) {
          throw const BookingException('Jadwal tidak tersedia.');
        }

        final slotStart = startTime.toDate();
        final slotEnd = endTime.toDate();
        final hasHeldClash = scheduleListSnapshot.docs.any((doc) {
          if (doc.id == scheduleId) return false;
          final data = doc.data();
          final existingStart = data['start_time'];
          final existingEnd = data['end_time'];
          if (!['held', 'booked'].contains(data['availability_status']) ||
              existingStart is! Timestamp ||
              existingEnd is! Timestamp) {
            return false;
          }
          return existingStart.toDate().isBefore(slotEnd) &&
              existingEnd.toDate().isAfter(slotStart);
        });
        if (hasHeldClash) {
          throw const BookingException('Jadwal bentrok dengan sesi lain.');
        }

        final menteeName =
            menteeSnapshot.data()?['name'] as String? ?? 'Mentee';
        final mentorName =
            mentorSnapshot.data()?['name'] as String? ?? 'Mentor';
        transaction.set(bookingRef, {
          'mentee_user_id': menteeId,
          'mentee_name': menteeName,
          'mentor_user_id': mentorId,
          'mentor_name': mentorName,
          'schedule_id': scheduleId,
          'start_time': startTime,
          'end_time': endTime,
          'booking_status': 'pending',
          'requested_at': now,
          'expires_at': Timestamp.fromDate(
            now.toDate().add(const Duration(minutes: _pendingMinutes)),
          ),
          'created_at': now,
        });
        transaction.set(bookingContactRef, {
          'mentee_user_id': menteeId,
          'mentor_user_id': mentorId,
          'mentee_email': menteeEmail,
          'mentee_whatsapp':
              menteeSnapshot.data()?['whatsapp'] as String? ?? '',
          'mentor_whatsapp': '',
        });
        transaction.update(scheduleRef, {
          'availability_status': 'held',
          'current_booking_id': bookingRef.id,
        });
      });
      return bookingRef.id;
    } on FirebaseException catch (error) {
      throw BookingException(_firebaseMessage(error));
    }
  }

  Future<DecisionResult> approveBooking(String bookingId) =>
      _decideBooking(bookingId, approve: true);

  Future<DecisionResult> rejectBooking(String bookingId) =>
      _decideBooking(bookingId, approve: false);

  Future<DecisionResult> decideBooking(
    String bookingId, {
    required bool approve,
  }) => _decideBooking(bookingId, approve: approve);

  Future<DecisionResult> _decideBooking(
    String bookingId, {
    required bool approve,
  }) async {
    final mentorId = _uid;
    final bookingRef = _bookings.doc(bookingId);
    try {
      final confirmedBookings = approve
          ? (await _bookings
                    .where('mentor_user_id', isEqualTo: mentorId)
                    .where('booking_status', isEqualTo: 'confirmed')
                    .limit(100)
                    .get())
                .docs
                .map((doc) => doc.data())
                .toList()
          : <Map<String, dynamic>>[];
      return await _db.runTransaction((transaction) async {
        final bookingSnapshot = await transaction.get(bookingRef);
        if (!bookingSnapshot.exists) {
          throw const BookingException('Booking tidak ditemukan.');
        }
        final booking = bookingSnapshot.data()!;
        if (booking['mentor_user_id'] != mentorId) {
          throw const BookingException('Booking ini bukan milik Anda.');
        }
        if (booking['booking_status'] != 'pending') {
          throw const BookingException(
            'Booking sudah tidak menunggu persetujuan.',
          );
        }

        final scheduleId = booking['schedule_id'] as String?;
        if (scheduleId == null || scheduleId.isEmpty) {
          throw const BookingException('Jadwal booking tidak ditemukan.');
        }
        final scheduleRef = _db.collection('mentor_schedules').doc(scheduleId);
        final scheduleSnapshot = await transaction.get(scheduleRef);
        final now = Timestamp.now();
        final expiresAt = booking['expires_at'];
        if (expiresAt is! Timestamp ||
            !expiresAt.toDate().isAfter(now.toDate())) {
          transaction.update(bookingRef, {'booking_status': 'expired'});
          if (scheduleSnapshot.exists &&
              scheduleSnapshot.data()?['availability_status'] == 'held' &&
              scheduleSnapshot.data()?['current_booking_id'] == bookingId) {
            transaction.update(scheduleRef, {
              'availability_status': 'available',
              'current_booking_id': FieldValue.delete(),
            });
          }
          return const DecisionResult('expired', null);
        }

        if (!approve) {
          transaction.update(bookingRef, {
            'booking_status': 'rejected',
            'rejection_reason': 'Ditolak oleh mentor',
          });
          _releaseHeldSlot(
            transaction,
            scheduleRef,
            scheduleSnapshot,
            bookingId,
          );
          return const DecisionResult('rejected', 'Ditolak oleh mentor');
        }

        final confirmed = confirmedBookings;
        final activeMenteeIds =
            confirmed
                .map((item) => item['mentee_user_id'])
                .whereType<String>()
                .toSet()
              ..remove(booking['mentee_user_id']);
        final start = booking['start_time'];
        final end = booking['end_time'];
        final clash =
            start is Timestamp &&
            end is Timestamp &&
            confirmed.any((item) {
              final itemStart = item['start_time'];
              final itemEnd = item['end_time'];
              if (itemStart is! Timestamp || itemEnd is! Timestamp) {
                return false;
              }
              return itemStart.toDate().isBefore(end.toDate()) &&
                  itemEnd.toDate().isAfter(start.toDate());
            });
        final slotHeld =
            scheduleSnapshot.exists &&
            scheduleSnapshot.data()?['availability_status'] == 'held' &&
            scheduleSnapshot.data()?['current_booking_id'] == bookingId;

        if (activeMenteeIds.length >= _maxActiveMentees || clash || !slotHeld) {
          transaction.update(bookingRef, {
            'booking_status': 'rejected',
            'rejection_reason': _autoRejectReason,
          });
          _releaseHeldSlot(
            transaction,
            scheduleRef,
            scheduleSnapshot,
            bookingId,
          );
          return const DecisionResult('rejected', _autoRejectReason);
        }

        transaction.update(bookingRef, {'booking_status': 'confirmed'});
        transaction.update(scheduleRef, {'availability_status': 'booked'});
        return const DecisionResult('confirmed', null);
      });
    } on FirebaseException catch (error) {
      throw BookingException(_firebaseMessage(error));
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final menteeId = _uid;
    final bookingRef = _bookings.doc(bookingId);
    try {
      await _db.runTransaction((transaction) async {
        final bookingSnapshot = await transaction.get(bookingRef);
        if (!bookingSnapshot.exists) {
          throw const BookingException('Booking tidak ditemukan.');
        }
        final booking = bookingSnapshot.data()!;
        if (booking['mentee_user_id'] != menteeId) {
          throw const BookingException('Booking ini bukan milik Anda.');
        }
        final status = booking['booking_status'];
        final now = Timestamp.now();
        if (status == 'pending') {
          final expiresAt = booking['expires_at'];
          if (expiresAt is! Timestamp ||
              !expiresAt.toDate().isAfter(now.toDate())) {
            throw const BookingException('Booking sudah kedaluwarsa.');
          }
        } else if (status == 'confirmed') {
          final start = booking['start_time'];
          if (start is! Timestamp ||
              start.toDate().difference(now.toDate()) <
                  const Duration(hours: 24)) {
            throw const BookingException(
              'Booking terkonfirmasi hanya bisa dibatalkan minimal 24 jam sebelum sesi.',
            );
          }
        } else {
          throw const BookingException(
            'Booking dengan status ini tidak dapat dibatalkan.',
          );
        }

        final scheduleId = booking['schedule_id'] as String?;
        final scheduleRef = scheduleId == null
            ? null
            : _db.collection('mentor_schedules').doc(scheduleId);
        final scheduleSnapshot = scheduleRef == null
            ? null
            : await transaction.get(scheduleRef);
        transaction.update(bookingRef, {'booking_status': 'cancelled'});
        if (scheduleRef != null && scheduleSnapshot != null) {
          _releaseHeldSlot(
            transaction,
            scheduleRef,
            scheduleSnapshot,
            bookingId,
          );
        }
      });
    } on FirebaseException catch (error) {
      throw BookingException(_firebaseMessage(error));
    }
  }

  Future<void> markCompleted(String bookingId) async {
    final mentorId = _uid;
    final bookingRef = _bookings.doc(bookingId);
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(bookingRef);
        if (!snapshot.exists) {
          throw const BookingException('Booking tidak ditemukan.');
        }
        final booking = snapshot.data()!;
        if (booking['mentor_user_id'] != mentorId) {
          throw const BookingException('Booking ini bukan milik Anda.');
        }
        if (booking['booking_status'] != 'confirmed') {
          throw const BookingException(
            'Hanya booking yang dikonfirmasi yang dapat diselesaikan.',
          );
        }
        final end = booking['end_time'];
        if (end is! Timestamp || end.toDate().isAfter(DateTime.now())) {
          throw const BookingException('Sesi belum berakhir.');
        }
        transaction.update(bookingRef, {'booking_status': 'completed'});
      });
    } on FirebaseException catch (error) {
      throw BookingException(_firebaseMessage(error));
    }
  }

  Future<int> expireBookings() async {
    final userId = _uid;
    final now = Timestamp.now();
    try {
      final dueBookings = await Future.wait([
        _bookings
            .where('mentee_user_id', isEqualTo: userId)
            .where('booking_status', isEqualTo: 'pending')
            .where('expires_at', isLessThan: now)
            .get(),
        _bookings
            .where('mentor_user_id', isEqualTo: userId)
            .where('booking_status', isEqualTo: 'pending')
            .where('expires_at', isLessThan: now)
            .get(),
      ]);
      final documents = {
        for (final snapshot in dueBookings)
          for (final document in snapshot.docs) document.id: document,
      }.values;

      var expiredCount = 0;
      for (final document in documents) {
        final expired = await _db.runTransaction<bool>((transaction) async {
          final bookingSnapshot = await transaction.get(document.reference);
          if (!bookingSnapshot.exists) return false;
          final booking = bookingSnapshot.data();
          if (booking == null ||
              booking['booking_status'] != 'pending' ||
              (booking['mentee_user_id'] != userId &&
                  booking['mentor_user_id'] != userId)) {
            return false;
          }
          final expiresAt = booking['expires_at'];
          if (expiresAt is! Timestamp ||
              !expiresAt.toDate().isBefore(DateTime.now())) {
            return false;
          }
          final scheduleId = booking['schedule_id'] as String?;
          final scheduleRef = scheduleId == null
              ? null
              : _db.collection('mentor_schedules').doc(scheduleId);
          final scheduleSnapshot = scheduleRef == null
              ? null
              : await transaction.get(scheduleRef);
          transaction.update(document.reference, {'booking_status': 'expired'});
          if (scheduleRef != null && scheduleSnapshot != null) {
            _releaseHeldSlot(
              transaction,
              scheduleRef,
              scheduleSnapshot,
              document.id,
            );
          }
          return true;
        });
        if (expired) expiredCount++;
      }
      return expiredCount;
    } on FirebaseException catch (error) {
      throw BookingException(_firebaseMessage(error));
    }
  }

  void _releaseHeldSlot(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> scheduleRef,
    DocumentSnapshot<Map<String, dynamic>> scheduleSnapshot,
    String bookingId,
  ) {
    final schedule = scheduleSnapshot.data();
    if (scheduleSnapshot.exists &&
        ['held', 'booked'].contains(schedule?['availability_status']) &&
        schedule?['current_booking_id'] == bookingId) {
      transaction.update(scheduleRef, {
        'availability_status': 'available',
        'current_booking_id': FieldValue.delete(),
      });
    }
  }

  Stream<List<Booking>> watchMenteeBookings(String menteeUid) => _bookings
      .where('mentee_user_id', isEqualTo: menteeUid)
      .orderBy('requested_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Booking.fromDoc).toList());

  Stream<List<Booking>> watchMentorBookings(String mentorUid) => _bookings
      .where('mentor_user_id', isEqualTo: mentorUid)
      .orderBy('requested_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Booking.fromDoc).toList());

  Stream<BookingContact?> watchBookingContact(String bookingId) => _db
      .collection('booking_contacts')
      .doc(bookingId)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists ? BookingContact.fromDoc(snapshot) : null,
      );

  Future<void> ensureConfirmedBookingContact(
    String bookingId, {
    required bool mentorView,
  }) async {
    final uid = _uid;
    final bookingRef = _bookings.doc(bookingId);
    final contactRef = _db.collection('booking_contacts').doc(bookingId);
    try {
      await _db.runTransaction((transaction) async {
        final bookingSnapshot = await transaction.get(bookingRef);
        final contactSnapshot = await transaction.get(contactRef);
        if (!bookingSnapshot.exists) {
          throw const BookingException('Booking tidak ditemukan.');
        }
        final booking = bookingSnapshot.data()!;
        if (!['confirmed', 'completed'].contains(booking['booking_status'])) {
          throw const BookingException(
            'Kontak hanya tersedia untuk booking yang disetujui.',
          );
        }

        if (mentorView) {
          if (booking['mentor_user_id'] != uid) {
            throw const BookingException('Booking ini bukan milik Anda.');
          }
          final mentorContactRef = _db
              .collection('mentor_contact_profiles')
              .doc(uid);
          final mentorContact = await transaction.get(mentorContactRef);
          final mentorWhatsApp =
              mentorContact.data()?['phone'] as String? ?? '';
          final contactData = {
            'mentee_user_id': booking['mentee_user_id'],
            'mentor_user_id': uid,
            'mentee_email': '',
            'mentee_whatsapp': '',
            'mentor_whatsapp': mentorWhatsApp,
          };
          if (contactSnapshot.exists) {
            transaction.update(contactRef, {'mentor_whatsapp': mentorWhatsApp});
          } else {
            transaction.set(contactRef, contactData);
          }
          return;
        }

        if (booking['mentee_user_id'] != uid) return;
        final menteeRef = _db.collection('users').doc(uid);
        final menteeSnapshot = await transaction.get(menteeRef);
        final email = _auth.currentUser?.email?.trim() ?? '';
        if (email.isEmpty || !menteeSnapshot.exists) {
          throw const BookingException(
            'Informasi kontak akun tidak tersedia. Perbarui profil lalu coba lagi.',
          );
        }
        final menteeWhatsApp =
            menteeSnapshot.data()?['whatsapp'] as String? ?? '';
        if (contactSnapshot.exists) {
          transaction.update(contactRef, {
            'mentee_email': email,
            'mentee_whatsapp': menteeWhatsApp,
          });
        } else {
          transaction.set(contactRef, {
            'mentee_user_id': uid,
            'mentor_user_id': booking['mentor_user_id'],
            'mentee_email': email,
            'mentee_whatsapp': menteeWhatsApp,
            'mentor_whatsapp': '',
          });
        }
      });
    } on FirebaseException catch (error) {
      throw BookingException(_firebaseMessage(error));
    }
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return 'Anda tidak memiliki izin untuk melakukan tindakan ini.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Koneksi bermasalah. Periksa internet Anda, lalu coba lagi.';
      case 'already-exists':
        return 'Slot ini sudah diajukan booking oleh pengguna lain.';
      default:
        return 'Booking gagal diperbarui. Silakan coba lagi.';
    }
  }
}
