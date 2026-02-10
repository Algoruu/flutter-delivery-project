import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

/// Firestore와 통신하는 서비스
class FirestoreService {
  final _reportsRef = FirebaseFirestore.instance.collection('reports');

  /// 제보 저장
  Future<void> addReport(Report report) async {
    await _reportsRef.add(report.toFirestore());
  }

  /// 모든 제보 불러오기
  Future<List<Report>> getReports() async {
    final snapshot = await _reportsRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
  }

  /// 실시간 제보 스트림
  Stream<List<Report>> getReportsStream() {
    return _reportsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList());
  }
}
