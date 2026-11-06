import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core palette
  static const slate = Color(0xFF333C3E); // primary
  static const ink = Color(0xFF252C2E); // text, nav bar
  static const slateSoft = Color(0xFF4A5558);
  static const peach = Color(0xFFFAAC77); // accent
  static const ground = Color(0xFFF0EFEE); // background
  static const card = Color(0xFFFFFFFF);
  static const stone = Color(0xFFC9C9BD); // borders, inactive chips
  static const muted = Color(0xFF606B6F); // secondary text
  static const line = Color(0xFFDCDCD3);
  static const tile = Color(0xFFE4E4DD);
  static const onDarkMuted = Color(0xFFC9C9BD);

  // Status colours (kept distinct from the palette so they read at a glance)
  static const submittedBg = Color(0xFFE3ECFA);
  static const submittedFg = Color(0xFF1C3F85);
  static const progressBg = Color(0xFFFDE3D2);
  static const progressFg = Color(0xFF8A4318);
  static const resolvedBg = Color(0xFFDCEFE3);
  static const resolvedFg = Color(0xFF1E5E38);
  static const closedBg = Color(0xFFE2E2DA);
  static const closedFg = Color(0xFF4A5558);

  // Feedback
  static const danger = Color(0xFFA3361A);
  static const dangerBg = Color(0xFFF9DDD2);
  static const success = Color(0xFF2E8A57);
}