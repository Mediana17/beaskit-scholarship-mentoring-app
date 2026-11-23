import 'package:cloud_firestore/cloud_firestore.dart';

class MentorProfile {
  const MentorProfile({
    required this.uid,
    required this.name,
    required this.expertise,
    required this.description,
    required this.verificationStatus,
    this.university = '',
    this.major = '',
    this.experience = '',
    this.phone = '',
    this.email = '',
    this.linkedin = '',
    this.rejectionReason,
  });

  final String uid;
  final String name;
  final String expertise;
  final String description;
  final String verificationStatus;
  final String university;
  final String major;
  final String experience;
  final String phone;
  final String email;
  final String linkedin;
  final String? rejectionReason;

  factory MentorProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      MentorProfile.fromMap(doc.id, doc.data() ?? {});

  factory MentorProfile.fromMap(String uid, Map<String, dynamic> data) {
    String text(String key) => data[key] as String? ?? '';
    return MentorProfile(
      uid: uid,
      name: text('name').isNotEmpty ? text('name') : 'Mentor',
      expertise: text('expertise'),
      description: text('description'),
      verificationStatus: text('verification_status'),
      university: text('university'),
      major: text('major'),
      experience: text('experience'),
      phone: text('phone'),
      email: text('email'),
      linkedin: text('linkedin'),
      rejectionReason: data['rejection_reason'] as String?,
    );
  }
}
