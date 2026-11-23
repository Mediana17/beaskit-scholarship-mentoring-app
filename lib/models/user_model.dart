import 'package:cloud_firestore/cloud_firestore.dart';

/// Sesuai koleksi `users`: name, email, role, whatsapp, created_at.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // mentee | mentor | admin
  final String whatsapp;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.whatsapp = '',
    this.createdAt,
  });

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final createdAt = d['created_at'];
    return UserModel(
      uid: doc.id,
      name: (d['name'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      role: (d['role'] ?? '') as String,
      whatsapp: d['whatsapp'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}