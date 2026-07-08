import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Try to use Inter, fallback to default font if not available
  static TextStyle _baseTextStyle(TextStyle style) {
    try {
      return GoogleFonts.inter(textStyle: style);
    } catch (e) {
      return style;
    }
  }

  static TextStyle get h1 => _baseTextStyle(
    const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
  );

  static TextStyle get h2 => _baseTextStyle(
    const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
  );
  
  static TextStyle get h3 => _baseTextStyle(
    const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );

  static TextStyle get bodyLarge => _baseTextStyle(
    const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    ),
  );

  static TextStyle get bodyMedium => _baseTextStyle(
    const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    ),
  );
  
  static TextStyle get bodyMediumMedium => _baseTextStyle(
    const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
  );

  static TextStyle get bodySmall => _baseTextStyle(
    const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    ),
  );
  
  static TextStyle get caption => _baseTextStyle(
    const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
  );
}
