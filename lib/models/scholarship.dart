import 'package:cloud_firestore/cloud_firestore.dart';

/// Sesuai koleksi `scholarships` (Bab 7): title, organizer, description,
/// requirements, deadline, application_url, status (published | archived).
class Scholarship {
  final String id;
  final String title;
  final String organizer;
  final String description;
  final String requirements;
  final String applicationUrl;
  final String status;
  final DateTime? deadline;
  final List<String> requiredDocuments;

  const Scholarship({
    required this.id,
    required this.title,
    required this.organizer,
    required this.description,
    required this.requirements,
    required this.applicationUrl,
    required this.status,
    required this.deadline,
    this.requiredDocuments = const [],
  });

  factory Scholarship.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final raw = d['deadline'];
    DateTime? deadline;
    if (raw is Timestamp) {
      deadline = raw.toDate();
    } else if (raw is String) {
      deadline = DateTime.tryParse(raw);
    }
    String s(String k) => (d[k] ?? '') as String;
    return Scholarship(
      id: doc.id,
      title: s('title'),
      organizer: s('organizer'),
      description: s('description'),
      requirements: s('requirements'),
      applicationUrl: s('application_url'),
      status: s('status'),
      deadline: deadline,
      requiredDocuments: (d['required_documents'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'organizer': organizer,
        'description': description,
        'requirements': requirements,
        'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
        'application_url': applicationUrl,
        'required_documents': requiredDocuments,
        'status': status,
      };

  bool get isClosed => deadline != null && deadline!.isBefore(DateTime.now());

  String get deadlineText {
    final d = deadline;
    if (d == null) return '-';
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }
}
