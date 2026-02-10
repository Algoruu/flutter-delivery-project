import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/report.dart';
import '../theme.dart';

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
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 헤더 ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_location_alt, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        '진입 정보 제보',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                        color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── 본문 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '유형 선택',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 입주민 전용 (빨간)
                  _TypeOptionCard(
                    icon: Icons.block,
                    color: AppTheme.dangerColor,
                    title: '입주민 전용 (진입금지)',
                    subtitle: '배달 오토바이 진입 불가',
                    selected: _selectedType == ReportType.residentOnly,
                    onTap: () => setState(() => _selectedType = ReportType.residentOnly),
                  ),
                  const SizedBox(height: 10),

                  // 방문자 전용 (초록)
                  _TypeOptionCard(
                    icon: Icons.check_circle,
                    color: AppTheme.safeColor,
                    title: '방문자 전용 (진입가능)',
                    subtitle: '배달 오토바이 진입 가능',
                    selected: _selectedType == ReportType.deliveryOk,
                    onTap: () => setState(() => _selectedType = ReportType.deliveryOk),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    '설명 (선택)',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '예: 후문으로 가면 배달 가능해요',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                child: Text(
                  '취소',
                  style: GoogleFonts.notoSansKr(
                    color: AppTheme.subtleText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final report = Report(
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                    type: _selectedType,
                    description: _descController.text.trim(),
                  );
                  Navigator.pop(context, report);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('제보하기'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 유형 선택 카드 위젯
class _TypeOptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? color : AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: AppTheme.subtleText,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
