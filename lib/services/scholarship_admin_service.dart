import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/scholarship.dart';

class ScholarshipAdminService {
  ScholarshipAdminService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _scholarships =>
      _db.collection('scholarships');

  Stream<List<Scholarship>> watchAll() =>
      _scholarships.snapshots().map((snapshot) {
        final scholarships = snapshot.docs.map(Scholarship.fromDoc).toList();
        scholarships.sort((a, b) {
          if (a.deadline == null) return b.deadline == null ? 0 : 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
        return scholarships;
      });

  Future<void> create(Scholarship data) async {
    _validate(data);
    try {
      await _scholarships.add({
        ...data.toMap(),
        'status': 'published',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<void> update(String id, Scholarship data) async {
    _validate(data);
    try {
      await _scholarships.doc(id).update({
        ...data.toMap(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<void> archive(String id) => _setStatus(id, 'archived');

  Future<void> restore(String id) => _setStatus(id, 'published');

  Future<void> _setStatus(String id, String status) async {
    try {
      await _scholarships.doc(id).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  void _validate(Scholarship data) {
    if (data.title.trim().isEmpty) {
      throw Exception('Masukkan judul beasiswa.');
    }
    if (data.organizer.trim().isEmpty) {
      throw Exception('Masukkan nama penyelenggara.');
    }
    if (data.deadline == null) {
      throw Exception('Pilih tenggat beasiswa.');
    }
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return 'Anda tidak memiliki izin untuk mengelola beasiswa.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Koneksi bermasalah. Periksa internet Anda, lalu coba lagi.';
      case 'not-found':
        return 'Beasiswa tidak ditemukan. Muat ulang daftar dan coba lagi.';
      default:
        return 'Beasiswa gagal disimpan. Silakan coba lagi.';
    }
  }
}
