import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mentor_schedule.dart';

class ScheduleService {
  ScheduleService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _schedules =>
      _db.collection('mentor_schedules');

  Stream<List<MentorSchedule>> watchMySchedules(String uid) => _schedules
      .where('mentor_user_id', isEqualTo: uid)
      .orderBy('start_time')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(MentorSchedule.fromDoc).toList());

  Stream<List<MentorSchedule>> watchAvailableSchedules(String mentorUid) =>
      _schedules
          .where('mentor_user_id', isEqualTo: mentorUid)
          .orderBy('start_time')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(MentorSchedule.fromDoc)
              .where((schedule) =>
                  schedule.availabilityStatus == 'available' &&
                  schedule.startTime.isAfter(DateTime.now()))
              .toList());

  Future<void> addSlot(DateTime start, DateTime end) async {
    if (!end.isAfter(start)) {
      throw Exception('Waktu selesai harus setelah waktu mulai.');
    }
    if (!start.isAfter(DateTime.now())) {
      throw Exception('Jadwal harus dimulai pada waktu mendatang.');
    }
    final user = _auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu.');

    try {
      final existing = await _schedules
          .where('mentor_user_id', isEqualTo: user.uid)
          .get();
      for (final doc in existing.docs) {
        final data = doc.data();
        if (!['available', 'held', 'booked']
            .contains(data['availability_status'])) {
          continue;
        }
        final existingStart = data['start_time'];
        final existingEnd = data['end_time'];
        if (existingStart is! Timestamp || existingEnd is! Timestamp) continue;
        final slotStart = existingStart.toDate();
        final slotEnd = existingEnd.toDate();
        if (start.isBefore(slotEnd) && end.isAfter(slotStart)) {
          throw Exception('Jadwal bertumpang tindih dengan slot aktif Anda.');
        }
      }

      await _schedules.add({
        'mentor_user_id': user.uid,
        'start_time': Timestamp.fromDate(start),
        'end_time': Timestamp.fromDate(end),
        'availability_status': 'available',
        'created_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<void> deactivate(String id) =>
      _setAvailability(id, expected: 'available', target: 'inactive');

  Future<void> activate(String id) =>
      _setAvailability(id, expected: 'inactive', target: 'available');

  Future<void> _setAvailability(
    String id, {
    required String expected,
    required String target,
  }) async {
    try {
      final doc = await _schedules.doc(id).get();
      if (!doc.exists) throw Exception('Slot jadwal tidak ditemukan.');
      final data = doc.data()!;
      final current = data['availability_status'];
      if (current == 'held' || current == 'booked') {
        throw Exception('Ada booking pada slot ini.');
      }
      if (current != expected) {
        throw Exception('Status slot sudah berubah. Muat ulang jadwal.');
      }
      if (target == 'available') {
        final start = data['start_time'];
        if (start is! Timestamp || !start.toDate().isAfter(DateTime.now())) {
          throw Exception('Slot yang sudah dimulai tidak dapat diaktifkan.');
        }
      }
      await _schedules.doc(id).update({'availability_status': target});
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return 'Anda tidak memiliki izin untuk mengelola jadwal.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Koneksi bermasalah. Periksa internet Anda, lalu coba lagi.';
      default:
        return 'Jadwal gagal diperbarui. Silakan coba lagi.';
    }
  }
}
