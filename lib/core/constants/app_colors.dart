import 'package:flutter/material.dart';

/// Palette de couleurs de l'application Finds
class AppColors {
  AppColors._();

  // Couleurs principales
  static const Color primary = Color(
    0xFF2E7D32,
  ); // Vert principal du projet (#2E7D32)
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryBackground = Color(0xFFF1F8F4); // Fond doux mint

  // Couleurs d'accentuation
  static const Color accent = Color(0xFF10B981);
  static const Color accentGold = Color(
    0xFFFFB300,
  ); // Pour le badge ⚡ Matching IA
  static const Color badgeDarkGreen = Color(0xFF144D29);

  // Surfaces et fonds
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSubtle = Color(0xFFF8FAF9);
  static const Color cardSurface = Color(0xFFF4F8F5);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF0F2F1);

  // Textes
  static const Color textPrimary = Color(0xFF111827); // Noir graphite élégant
  static const Color textSecondary = Color(0xFF6B7280); // Gris sous-titres
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Statuts
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Jetons utilisés par les écrans (maquettes Stitch)
  static const Color pageBackground = Color(0xFFFBF9F9);
  static const Color textStrong = Color(0xFF1B1C1C);
  static const Color textBody = Color(0xFF40493D);
  // Foncé par rapport à la maquette (0xFF707A6C) pour un contraste ≥ 4,5:1.
  static const Color textSubtle = Color(0xFF5B6557);
  static const Color primarySoft = Color(0xFFE8F5E9);
  static const Color inputFill = Color(0xFFF5F3F3);
  static const Color divider = Color(0xFFF0EFEF);
  static const Color chipBackground = Color(0xFFEFEDED);
  static const Color chipBadge = Color(0xFFE3E2E2);
  static const Color successDark = Color(0xFF00731E);
  static const Color successDeep = Color(0xFF006E1C);
  static const Color errorSoft = Color(0xFFFFDAD6);
  static const Color errorDark = Color(0xFFBA1A1A);
  static const Color infoSoft = Color(0xFFD6E3FF);
  static const Color infoDark = Color(0xFF0054A7);
  static const Color whatsapp = Color(0xFF25D366);
}
