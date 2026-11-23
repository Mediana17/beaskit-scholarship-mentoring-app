import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Koleksi `bookmarks` (Bab 7). ID dokumen = `{uid}_{scholarshipId}` sehingga
/// pasangan user + beasiswa otomatis unik (tidak ada duplikasi).
class BookmarkService {
  BookmarkService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Pengguna belum login.');
    return u.uid;
  }

  /// ID beasiswa yang di-bookmark pengguna (real-time).
  Stream<Set<String>> watchBookmarkedIds() => _db
      .collection('bookmarks')
      .where('user_id', isEqualTo: _uid)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()['scholarship_id'] as String).toSet());

  Future<void> toggle(String scholarshipId,
      {required bool currentlyBookmarked}) async {
    final ref = _db.collection('bookmarks').doc('${_uid}_$scholarshipId');
    if (currentlyBookmarked) {
      await ref.delete();
    } else {
      await ref.set({
        'user_id': _uid,
        'scholarship_id': scholarshipId,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }
}
