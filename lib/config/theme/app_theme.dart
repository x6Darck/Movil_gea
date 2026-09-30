import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gea_app/config/theme/app_tokens.dart';

class AppTheme {
  // Alias retrocompatibles (apuntan a tokens dark). NO renombrar: los usan widgets existentes.
  static const Color primaryColor = AppTokens.primary;
  static const Color primaryHover = AppTokens.primaryHover;
  static const Color primaryLight = AppTokens.primaryLight;

  static const Color backgroundColor = AppTokens.background;
  static const Color surfaceColor = AppTokens.surface1;

  static const Color textMain = AppTokens.textPrimary;
  static const Color textSecondary = AppTokens.textSecondary;
  static const Color textMuted = AppTokens.textMuted;

  static const Color borderColor = AppTokens.surface3;
  static const Color dividerColor = AppTokens.surface3;

  static const Color successColor = AppTokens.success;
  static const Color warningColor = AppTokens.warning;
  static const Color importantColor = AppTokens.important;
  static const Color errorColor = AppTokens.error;

  /// Nombres conservados por compatibilidad (los usan widgets existentes) —
  /// ambos apuntan al mismo tema claro; la app no tiene modo oscuro.
  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppTokens.primary,
        secondary: AppTokens.textSecondary,
        surface: AppTokens.surface1,
        onSurface: AppTokens.textPrimary,
        error: AppTokens.error,
      ),
      scaffoldBackgroundColor: AppTokens.background,
      dividerColor: AppTokens.surface3,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700, color: AppTokens.textPrimary, fontSize: 32, letterSpacing: -0.5),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700, color: AppTokens.textPrimary, fontSize: 22, letterSpacing: -0.3),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600, color: AppTokens.textPrimary, fontSize: 17),
        bodyLarge: GoogleFonts.inter(
          color: AppTokens.textSecondary, fontSize: 15, height: 1.5),
        bodyMedium: GoogleFonts.inter(
          color: AppTokens.textSecondary, fontSize: 13, height: 1.5),
        bodySmall: GoogleFonts.inter(
          color: AppTokens.textMuted, fontSize: 13),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600, color: AppTokens.textSecondary, fontSize: 11, letterSpacing: 0.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppTokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
          fontFamily: 'Inter', letterSpacing: -0.5),
        iconTheme: IconThemeData(color: AppTokens.textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: const BorderSide(color: AppTokens.glassBorder, width: 1),
        ),
        color: AppTokens.surface1,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white.withValues(alpha: 0.1);
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.textPrimary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppTokens.glassBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface2,
        hoverColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.surface3)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.surface3)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.error)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppTokens.textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: AppTokens.textMuted, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppTokens.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet))),
      ),
      // Sin esto, los ~8 "Divider()" del código (sin color explícito) no
      // heredan dividerColor de arriba — Material 3 los resuelve contra
      // colorScheme.outlineVariant en vez de dividerColor cuando no hay
      // DividerThemeData, y como ColorScheme.light() no deriva esos campos
      // de nuestros tokens, salían con el gris/negro por defecto de Material.
      dividerTheme: const DividerThemeData(
        color: AppTokens.surface3,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
