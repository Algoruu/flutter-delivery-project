import 'package:cloud_firestore/cloud_firestore.dart';

/// 제보 유형
enum ReportType {
  residentOnly, // 입주민 전용 (진입금지)
  deliveryOk,   // 방문자 전용 (진입가능)
}

/// 제보 데이터 모델
class Report {
  final String? id;
  final double latitude;
  final double longitude;
  final ReportType type;
  final String description;
  final DateTime createdAt;

  Report({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Firestore 문서 → Report 객체
  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      type: data['type'] == 'residentOnly'
          ? ReportType.residentOnly
          : ReportType.deliveryOk,
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Report 객체 → Firestore 문서
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'type': type == ReportType.residentOnly ? 'residentOnly' : 'deliveryOk',
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
