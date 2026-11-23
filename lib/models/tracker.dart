import 'package:cloud_firestore/cloud_firestore.dart';

enum PreparationStatus {
  belumDimulai,
  sedangDipersiapkan,
  sudahMendaftar;

  String get firestoreValue {
    switch (this) {
      case PreparationStatus.belumDimulai:
        return 'belum_dimulai';
      case PreparationStatus.sedangDipersiapkan:
        return 'sedang_dipersiapkan';
      case PreparationStatus.sudahMendaftar:
        return 'sudah_mendaftar';
    }
  }

  String get label {
    switch (this) {
      case PreparationStatus.belumDimulai:
        return 'Belum dimulai';
      case PreparationStatus.sedangDipersiapkan:
        return 'Sedang dipersiapkan';
      case PreparationStatus.sudahMendaftar:
        return 'Sudah mendaftar';
    }
  }

  static PreparationStatus fromFirestore(String? value) {
    switch (value) {
      case 'sedang_dipersiapkan':
        return PreparationStatus.sedangDipersiapkan;
      case 'sudah_mendaftar':
        return PreparationStatus.sudahMendaftar;
      case 'belum_dimulai':
      default:
        return PreparationStatus.belumDimulai;
    }
  }
}

class Tracker {
  const Tracker({
    required this.id,
    required this.userId,
    required this.scholarshipId,
    required this.scholarshipTitle,
    required this.deadline,
    required this.preparationStatus,
    required this.updatedAt,
    this.documents = const [],
  });

  final String id;
  final String userId;
  final String scholarshipId;
  final String scholarshipTitle;
  final DateTime? deadline;
  final PreparationStatus preparationStatus;
  final DateTime? updatedAt;
  final List<TrackerDocument> documents;

  factory Tracker.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDeadline = data['deadline'];
    final rawUpdatedAt = data['updated_at'];
    return Tracker(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      scholarshipId: data['scholarship_id'] as String? ?? '',
      scholarshipTitle: data['scholarship_title'] as String? ?? '',
      deadline: rawDeadline is Timestamp ? rawDeadline.toDate() : null,
      preparationStatus: PreparationStatus.fromFirestore(
        data['preparation_status'] as String?,
      ),
      updatedAt: rawUpdatedAt is Timestamp ? rawUpdatedAt.toDate() : null,
    );
  }

  double get progress {
    if (preparationStatus == PreparationStatus.sudahMendaftar) return 1;
    if (documents.isEmpty) return 0;
    final completed = documents.where((document) => document.isCompleted).length;
    return completed / documents.length;
  }

  Tracker withDocuments(List<TrackerDocument> value) => Tracker(
        id: id,
        userId: userId,
        scholarshipId: scholarshipId,
        scholarshipTitle: scholarshipTitle,
        deadline: deadline,
        preparationStatus: preparationStatus,
        updatedAt: updatedAt,
        documents: value,
      );

  String get deadlineText {
    final value = deadline;
    if (value == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}

class TrackerDocument {
  const TrackerDocument({
    required this.id,
    required this.userId,
    required this.trackerId,
    required this.documentName,
    required this.isCompleted,
    required this.index,
  });

  final String id;
  final String userId;
  final String trackerId;
  final String documentName;
  final bool isCompleted;
  final int index;

  factory TrackerDocument.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final indexText = doc.id.split('_').last;
    return TrackerDocument(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      trackerId: data['tracker_id'] as String? ?? '',
      documentName: data['document_name'] as String? ?? '',
      isCompleted: data['completion_status'] as bool? ?? false,
      index: int.tryParse(indexText) ?? 0,
    );
  }
}
