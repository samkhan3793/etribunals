import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF14384A);
  static const Color secondary = Color(0xFFF6F3EE);
  static const Color accent = Color(0xFF1C7A68);
  static const Color gold = Color(0xFFC4A265);
  static const Color field = Color(0xFFFFFFFF);
  static const Color tile = Color(0xFFE6F3EF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color background = secondary;
  static const Color textPrimary = Color(0xFF1A2B33);
  static const Color textMuted = Color(0xFF5C6E76);
  static const Color white = Colors.white;
  static const Color heroStart = Color(0xFF0E2A36);
  static const Color heroMid = Color(0xFF164656);
  static const Color heroEnd = Color(0xFF1C7A68);
  static const Color outline = Color(0x1A14384A);
  static const Color ink = Color(0xFF0B2430);
  static const Color paper = Color(0xFFFFFDF8);
  static const Color stampRed = Color(0xFFB42318);
  static const Color stampBlue = Color(0xFF125D95);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [heroStart, heroMid, heroEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
