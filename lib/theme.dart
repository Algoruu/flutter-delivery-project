import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전체 테마 — Material 3 기반
class AppTheme {
  AppTheme._();

  // ── 브랜드 색상 ──
  static const Color primaryColor = Color(0xFF2D6A4F);   // 깊은 초록 (배달 = 이동)
  static const Color secondaryColor = Color(0xFF52B788);  // 밝은 초록
  static const Color dangerColor = Color(0xFFE63946);     // 빨강 (진입 금지)
  static const Color safeColor = Color(0xFF40916C);       // 진입 가능
  static const Color surfaceColor = Color(0xFFF8FAF7);    // 약간 녹색 틴트 배경
  static const Color darkText = Color(0xFF1B1B1F);
  static const Color subtleText = Color(0xFF6B7280);

  // ── 테마 데이터 ──
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: surfaceColor,
    );

    final textTheme = GoogleFonts.notoSansKrTextTheme().copyWith(
      headlineLarge: GoogleFonts.notoSansKr(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
      headlineMedium: GoogleFonts.notoSansKr(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      titleLarge: GoogleFonts.notoSansKr(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      titleMedium: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkText,
      ),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkText,
      ),
      bodySmall: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: subtleText,
      ),
      labelLarge: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: surfaceColor,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
        contentTextStyle: GoogleFonts.notoSansKr(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkText,
        ),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: Colors.white,
        ),
      ),

      // ── FilledButton ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: subtleText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── ElevatedButton ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
      ),

      // ── RadioListTile / Radio ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return subtleText;
        }),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 0,
      ),
    );
  }
}
