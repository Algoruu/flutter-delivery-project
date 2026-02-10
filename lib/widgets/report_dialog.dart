import 'package:flutter/material.dart';
import '../models/report.dart';

/// 제보 다이얼로그 — 앱과 웹 공통으로 사용
class ReportDialog extends StatefulWidget {
  final double latitude;
  final double longitude;

  const ReportDialog({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  /// 다이얼로그를 띄우고 Report를 반환 (취소 시 null)
  static Future<Report?> show(
    BuildContext context, {
    required double latitude,
    required double longitude,
  }) {
    return showDialog<Report>(
      context: context,
      builder: (context) => ReportDialog(
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportType _selectedType = ReportType.residentOnly;
  final _descController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📍 진입 정보 제보'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '위치: (${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)})',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            const Text('유형 선택', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 입주민 전용 (빨간)
            RadioListTile<ReportType>(
              title: const Text('🔴 입주민 전용 (진입금지)'),
              subtitle: const Text('배달 오토바이 진입 불가'),
              value: ReportType.residentOnly,
              groupValue: _selectedType,
              activeColor: Colors.red,
              onChanged: (v) => setState(() => _selectedType = v!),
            ),

            // 방문자 전용 (초록)
            RadioListTile<ReportType>(
              title: const Text('🟢 방문자 전용 (진입가능)'),
              subtitle: const Text('배달 오토바이 진입 가능'),
              value: ReportType.deliveryOk,
              groupValue: _selectedType,
              activeColor: Colors.green,
              onChanged: (v) => setState(() => _selectedType = v!),
            ),

            const SizedBox(height: 16),
            const Text('설명 (선택)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '예: 후문으로 가면 배달 가능해요',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final report = Report(
              latitude: widget.latitude,
              longitude: widget.longitude,
              type: _selectedType,
              description: _descController.text.trim(),
            );
            Navigator.pop(context, report);
          },
          child: const Text('제보하기'),
        ),
      ],
    );
  }
}
