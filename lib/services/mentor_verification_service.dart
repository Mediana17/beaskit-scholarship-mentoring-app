import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mentor_profile.dart';

class MentorVerificationService {
  MentorVerificationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<MentorProfile>> watchPending() => _db
      .collection('mentor_profiles')
      .where('verification_status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(MentorProfile.fromDoc).toList())
      .handleError((Object error) {
        if (error is FirebaseException) {
          throw Exception(_firebaseMessage(error));
        }
        throw error;
      });

  Future<MentorProfile?> getMentorForAdmin(String uid) async {
    try {
      final profileSnapshot = await _db
          .collection('mentor_profiles')
          .doc(uid)
          .get();
      if (!profileSnapshot.exists) return null;

      final data = profileSnapshot.data()!;
      final contactSnapshot = await _db
          .collection('mentor_contact_profiles')
          .doc(uid)
          .get();
      final contact = contactSnapshot.data();
      return MentorProfile.fromMap(uid, {
        ...data,
        'phone': contact?['phone'] ?? data['phone'] ?? '',
        'email': contact?['email'] ?? data['email'] ?? '',
        'linkedin': contact?['linkedin'] ?? data['linkedin'] ?? '',
      });
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<void> approveMentor(String uid) =>
      _setVerification(uid: uid, status: 'verified');

  Future<void> rejectMentor(String uid, String reason) =>
      _setVerification(uid: uid, status: 'rejected', rejectionReason: reason);

  Future<void> _setVerification({
    required String uid,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      final profileRef = _db.collection('mentor_profiles').doc(uid);
      final profileSnapshot = await profileRef.get();
      if (!profileSnapshot.exists) {
        throw Exception('Profil mentor tidak ditemukan.');
      }

      final mentor = profileSnapshot.data()!;
      final batch = _db.batch();
      batch.update(profileRef, {
        'verification_status': status,
        'rejection_reason': status == 'verified' ? null : rejectionReason,
        if (status == 'verified') 'verified_at': FieldValue.serverTimestamp(),
        if (status == 'rejected') 'rejected_at': FieldValue.serverTimestamp(),
        'phone': FieldValue.delete(),
        'email': FieldValue.delete(),
        'linkedin': FieldValue.delete(),
      });
      if (['phone', 'email', 'linkedin'].any(mentor.containsKey)) {
        batch.set(_db.collection('mentor_contact_profiles').doc(uid), {
          'phone': mentor['phone'] as String? ?? '',
          'email': mentor['email'] as String? ?? '',
          'linkedin': mentor['linkedin'] as String? ?? '',
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      batch.set(_db.collection('mentor_public_profiles').doc(uid), {
        'name': mentor['name'] as String? ?? 'Mentor',
        'university': mentor['university'] as String? ?? '',
        'major': mentor['major'] as String? ?? '',
        'experience': mentor['experience'] as String? ?? '',
        'expertise': mentor['expertise'] as String? ?? '',
        'description': mentor['description'] as String? ?? '',
        'verification_status': status,
      }, SetOptions(merge: true));
      await batch.commit();
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return 'Anda tidak memiliki izin untuk memverifikasi mentor.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Koneksi bermasalah. Periksa internet Anda, lalu coba lagi.';
      case 'not-found':
        return 'Profil mentor tidak ditemukan. Muat ulang dan coba lagi.';
      default:
        return 'Data mentor gagal diproses. Silakan coba lagi.';
    }
  }
}
