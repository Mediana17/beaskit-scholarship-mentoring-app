class MentorProfile {
  final String mentorProfileId;
  final String userId;
  final String expertise;
  final String description;
  final String verificationStatus;

  MentorProfile({
    required this.mentorProfileId,
    required this.userId,
    required this.expertise,
    required this.description,
    required this.verificationStatus,
  });

  // Fungsi untuk membaca data dari Firestore
  factory MentorProfile.fromMap(String id, Map<String, dynamic> map) {
    return MentorProfile(
      mentorProfileId: id,
      userId: map['user_id'] ?? '',
      expertise: map['expertise'] ?? '',
      description: map['description'] ?? '',
      verificationStatus: map['verification_status'] ?? 'pending',
    );
  }
}