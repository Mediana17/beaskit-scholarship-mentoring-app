import 'package:cloud_firestore/cloud_firestore.dart';

class MentorSchedule {
  const MentorSchedule({
    required this.id,
    required this.mentorUserId,
    required this.startTime,
    required this.endTime,
    required this.availabilityStatus,
  });

  final String id;
  final String mentorUserId;
  final DateTime startTime;
  final DateTime endTime;
  final String availabilityStatus;

  factory MentorSchedule.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MentorSchedule(
      id: doc.id,
      mentorUserId: data['mentor_user_id'] as String? ?? '',
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      availabilityStatus: data['availability_status'] as String? ?? '',
    );
  }

  String get statusLabel => switch (availabilityStatus) {
        'available' => 'Tersedia',
        'held' => 'Ditahan (menunggu persetujuan)',
        'booked' => 'Terbooking',
        'inactive' => 'Nonaktif',
        _ => 'Status tidak diketahui',
      };

  bool get isBooked =>
      availabilityStatus == 'held' || availabilityStatus == 'booked';
}
