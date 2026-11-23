import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mentor_profile.dart';

class MentorProfileService {
  MentorProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu.');
    return user.uid;
  }

  String? get currentEmail => _auth.currentUser?.email;

  Future<MentorProfile?> getProfile(String uid) async {
    try {
      final doc = await _db.collection('mentor_profiles').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final contactRef = _db.collection('mentor_contact_profiles').doc(uid);
      final contactSnapshot = await contactRef.get();
      final legacyContact = {
        'phone': data['phone'] as String? ?? '',
        'email': data['email'] as String? ?? '',
        'linkedin': data['linkedin'] as String? ?? '',
      };
      final contact = contactSnapshot.data() ?? legacyContact;
      final profileData = Map<String, dynamic>.from(data)
        ..addAll({
          'phone': contact['phone'] as String? ?? '',
          'email': contact['email'] as String? ?? '',
          'linkedin': contact['linkedin'] as String? ?? '',
        });

      if (uid == currentUserId) {
        final batch = _db.batch();
        batch.set(_db.collection('mentor_public_profiles').doc(uid), {
          ..._publicFields(data),
          'verification_status': data['verification_status'] ?? 'pending',
        }, SetOptions(merge: true));
        if (!contactSnapshot.exists) {
          batch.set(contactRef, {
            ...legacyContact,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        if (['phone', 'email', 'linkedin'].any(data.containsKey)) {
          batch.update(_db.collection('mentor_profiles').doc(uid), {
            'phone': FieldValue.delete(),
            'email': FieldValue.delete(),
            'linkedin': FieldValue.delete(),
          });
        }
        await batch.commit();
      }

      return MentorProfile.fromMap(uid, profileData);
    } on FirebaseException {
      throw Exception('Profil mentor gagal dimuat. Periksa koneksi Anda.');
    }
  }

  Stream<List<MentorProfile>> watchVerifiedMentors() => _db
      .collection('mentor_public_profiles')
      .where('verification_status', isEqualTo: 'verified')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(MentorProfile.fromDoc).toList());

  Future<void> saveProfile({
    required String university,
    required String major,
    required String experience,
    required String expertise,
    required String description,
    required String phone,
    required String email,
    required String linkedin,
  }) async {
    try {
      final profileRef = _db.collection('mentor_profiles').doc(currentUserId);
      final profileSnapshot = await profileRef.get();
      final status =
          profileSnapshot.data()?['verification_status'] as String? ??
          'pending';
      final publicFields = {
        'name': profileSnapshot.data()?['name'] as String? ?? 'Mentor',
        'university': university.trim(),
        'major': major.trim(),
        'experience': experience.trim(),
        'expertise': expertise.trim(),
        'description': description.trim(),
        'verification_status': status,
      };
      final batch = _db.batch();
      batch.set(profileRef, {
        ...publicFields,
        'phone': FieldValue.delete(),
        'email': FieldValue.delete(),
        'linkedin': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(
        _db.collection('mentor_public_profiles').doc(currentUserId),
        publicFields,
        SetOptions(merge: true),
      );
      batch.set(_db.collection('mentor_contact_profiles').doc(currentUserId), {
        'phone': phone.trim(),
        'email': email.trim(),
        'linkedin': linkedin.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
    } on FirebaseException {
      throw Exception('Profil gagal disimpan. Periksa koneksi dan izin akun.');
    }
  }

  Map<String, dynamic> _publicFields(Map<String, dynamic> data) => {
    'name': data['name'] as String? ?? 'Mentor',
    'university': data['university'] as String? ?? '',
    'major': data['major'] as String? ?? '',
    'experience': data['experience'] as String? ?? '',
    'expertise': data['expertise'] as String? ?? '',
    'description': data['description'] as String? ?? '',
  };
}
