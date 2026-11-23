import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') return;
      rethrow;
    }
  }

  Future<void> logout() => _auth.signOut();

  /// Registrasi Mentee atau Mentor (role admin TIDAK bisa didaftarkan dari sini).
  /// Dokumen `users` (dan `mentor_profiles` untuk Mentor) ditulis dalam satu batch
  /// agar tidak ada akun setengah jadi.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'mentee' | 'mentor'
    String whatsapp = '',
  }) async {
    if (role != 'mentee' && role != 'mentor') {
      throw ArgumentError('Role tidak valid.');
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    try {
      final batch = _db.batch();
      batch.set(_db.collection('users').doc(user.uid), {
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'whatsapp': whatsapp.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
      if (role == 'mentor') {
        batch.set(_db.collection('mentor_profiles').doc(user.uid), {
          'name': name
              .trim(), // disalin agar direktori mentor tidak perlu baca `users`
          'university': '',
          'major': '',
          'experience': '',
          'verification_status': 'pending',
          'rejection_reason': null,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {
      // Gagal menyimpan profil: hapus akun auth agar email bisa dipakai lagi.
      await user.delete();
      rethrow;
    }
  }

  /// Pesan galat berbahasa Indonesia untuk ditampilkan ke pengguna.
  static String messageFor(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'missing-email':
          return 'Email wajib diisi.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email atau password salah.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        case 'network-request-failed':
          return 'Periksa koneksi internet Anda.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar.';
        case 'weak-password':
          return 'Password terlalu lemah (minimal 6 karakter).';
      }
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
