import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  /// Null jika dokumen profil belum ada (mis. registrasi sedang berlangsung).
  Stream<UserModel?> watchUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromDoc(doc) : null);

  Stream<List<UserModel>> watchAllUsers() => _db
      .collection('users')
      .snapshots()
      .map((snapshot) {
        final users = snapshot.docs.map(UserModel.fromDoc).toList();
        users.sort((a, b) {
          if (a.createdAt == null) return b.createdAt == null ? 0 : 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return users;
      })
      .handleError((Object error) {
        if (error is FirebaseException) {
          throw Exception(_firebaseMessage(error));
        }
        throw error;
      });

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return 'Anda tidak memiliki izin untuk melihat daftar pengguna.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Koneksi bermasalah. Periksa internet Anda, lalu coba lagi.';
      default:
        return 'Daftar pengguna gagal dimuat. Silakan coba lagi.';
    }
  }
}
