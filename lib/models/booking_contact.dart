import 'package:cloud_firestore/cloud_firestore.dart';

class BookingContact {
  const BookingContact({
    required this.menteeEmail,
    required this.menteeWhatsApp,
    required this.mentorWhatsApp,
  });

  final String menteeEmail;
  final String menteeWhatsApp;
  final String mentorWhatsApp;

  factory BookingContact.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return BookingContact(
      menteeEmail: data['mentee_email'] as String? ?? '',
      menteeWhatsApp: data['mentee_whatsapp'] as String? ?? '',
      mentorWhatsApp: data['mentor_whatsapp'] as String? ?? '',
    );
  }
}
