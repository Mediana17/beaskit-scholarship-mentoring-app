import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/scholarship.dart';

class ScholarshipService {
  ScholarshipService({FirebaseFirestore? firestore})
      : _col = (firestore ?? FirebaseFirestore.instance).collection('scholarships');
  final CollectionReference<Map<String, dynamic>> _col;

  /// Hanya beasiswa berstatus published (F-04), diurutkan dari tenggat terdekat.
  Stream<List<Scholarship>> watchPublished() {
    return _col.where('status', isEqualTo: 'published').snapshots().map((s) {
      final list = s.docs.map(Scholarship.fromDoc).toList();
      list.sort((a, b) {
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });
      return list;
    });
  }

  /// Beasiswa yang sudah diarsipkan/dihapus akan dilewati (null).
  Future<List<Scholarship>> getPublishedByIds(Iterable<String> ids) async {
    final result = await Future.wait(ids.map((id) async {
      try {
        final doc = await _col.doc(id).get();
        if (!doc.exists) return null;
        final s = Scholarship.fromDoc(doc);
        return s.status == 'published' ? s : null;
      } catch (_) {
        return null;
      }
    }));
    return result.whereType<Scholarship>().toList();
  }
}
