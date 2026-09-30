import 'package:flutter/material.dart';

/// Fuente única de verdad de los tokens visuales de GEA (tema claro).
class AppTokens {
  AppTokens._();

  // ── Superficies ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFF7F7F8); // gris casi blanco (scaffold)
  static const Color surface1 = Color(0xFFFFFFFF);    // cards base, blanco puro
  static const Color surface2 = Color(0xFFF1F2F4);    // inputs, chips
  static const Color surface3 = Color(0xFFE2E4E8);    // dividers, bordes

  // ── Marca ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE53935);    // rojo GEA
  static const Color primaryHover = Color(0xFFC62828);
  static const Color primaryGlow = Color(0x33E53935);  // 20% — sombra roja
  static const Color primaryLight = Color(0x14E53935); // 8% — superficies con tinte

  // ── Texto ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Semánticos (ajustados para contraste sobre fondo claro) ─────────
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color important = Color(0xFFD97706); // alias eventos importantes
  static const Color error = Color(0xFFDC2626);

  // ── Glass ───────────────────────────────────────────────────────────
  static const Color glassBorder = Color(0x14000000); // 8% negro
  static const Color glassFill = Color(0x08000000);   // 3% negro
  static const double glassBlur = 14.0;

  // ── Radios ──────────────────────────────────────────────────────────
  static const double radiusCard = 16;
  static const double radiusInput = 12;
  static const double radiusPill = 100;
  static const double radiusSheet = 24;

  // ── Sombra de color (elementos elevados) ────────────────────────────
  static const List<BoxShadow> glowShadow = [
    BoxShadow(color: primaryGlow, blurRadius: 20, spreadRadius: -4, offset: Offset(0, 8)),
  ];
}
