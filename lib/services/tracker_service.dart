import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/scholarship.dart';
import '../models/tracker.dart';

class TrackerService {
  TrackerService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _defaultDocuments = [
    'KTP/Identitas',
    'Transkrip nilai',
    'CV',
    'Esai/motivation letter',
    'Surat rekomendasi',
  ];

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _trackers =>
      _db.collection('trackers');

  String _trackerId(String uid, String scholarshipId) =>
      '${uid}_$scholarshipId';

  String trackerIdFor(String scholarshipId) =>
      _trackerId(_uid, scholarshipId);

  Future<bool> exists(String scholarshipId) async {
    try {
      final uid = _uid;
      final snapshot =
          await _trackers.doc(_trackerId(uid, scholarshipId)).get();
      return snapshot.exists;
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<bool> addToTracker(Scholarship scholarship) async {
    try {
      final uid = _uid;
      final trackerId = _trackerId(uid, scholarship.id);
      final trackerRef = _trackers.doc(trackerId);
      if ((await trackerRef.get()).exists) return false;

      final batch = _db.batch();
      batch.set(trackerRef, {
        'user_id': uid,
        'scholarship_id': scholarship.id,
        'scholarship_title': scholarship.title,
        'deadline': scholarship.deadline == null
            ? null
            : Timestamp.fromDate(scholarship.deadline!),
        'preparation_status': PreparationStatus.belumDimulai.firestoreValue,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      final documents = scholarship.requiredDocuments.isEmpty
          ? _defaultDocuments
          : scholarship.requiredDocuments;
      for (var index = 0; index < documents.length; index++) {
        batch.set(_db.collection('tracker_documents').doc('${trackerId}_$index'), {
          'user_id': uid,
          'tracker_id': trackerId,
          'document_name': documents[index],
          'completion_status': false,
        });
      }
      await batch.commit();
      return true;
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Stream<List<Tracker>> watchMyTrackers() {
    final uid = _uid;
    return _trackers
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final trackers = snapshot.docs.map(Tracker.fromDoc).toList();
      trackers.sort((a, b) {
        if (a.updatedAt == null) return b.updatedAt == null ? 0 : 1;
        if (b.updatedAt == null) return -1;
        return b.updatedAt!.compareTo(a.updatedAt!);
      });
      return trackers;
    });
  }

  Stream<Tracker?> watchTracker(String trackerId) {
    final uid = _uid;
    return _trackers.doc(trackerId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data()?['user_id'] != uid) return null;
      return Tracker.fromDoc(snapshot);
    });
  }

  Stream<List<TrackerDocument>> watchDocuments(String trackerId) {
    final uid = _uid;
    return _db
        .collection('tracker_documents')
        .where('tracker_id', isEqualTo: trackerId)
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final documents = snapshot.docs.map(TrackerDocument.fromDoc).toList();
      documents.sort((a, b) => a.index.compareTo(b.index));
      return documents;
    });
  }

  Future<void> setStatus(
    String trackerId,
    PreparationStatus status,
  ) async {
    try {
      await _trackers.doc(trackerId).update({
        'preparation_status': status.firestoreValue,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<void> setDocumentCompleted(String documentId, bool value) async {
    try {
      final uid = _uid;
      final documentRef = _db.collection('tracker_documents').doc(documentId);
      final snapshot = await documentRef.get();
      if (!snapshot.exists || snapshot.data()?['user_id'] != uid) {
        throw Exception('Dokumen checklist tidak ditemukan.');
      }
      final trackerId = snapshot.data()?['tracker_id'] as String?;
      if (trackerId == null || trackerId.isEmpty) {
        throw Exception('Tracker tidak ditemukan.');
      }
      final batch = _db.batch();
      batch.update(documentRef, {'completion_status': value});
      batch.update(_trackers.doc(trackerId), {
        'updated_at': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return 'Anda tidak memiliki izin untuk mengakses tracker ini.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Koneksi bermasalah. Periksa internet Anda, lalu coba lagi.';
      case 'not-found':
        return 'Data tracker tidak ditemukan. Muat ulang dan coba lagi.';
      default:
        return 'Tracker gagal diperbarui. Silakan coba lagi.';
    }
  }
}
