import 'package:flutter/material.dart';

/// Design tokens inspired by Apple Human Interface Guidelines.
abstract final class ClefDs {
  // Colors
  static const appleBlue = Color(0xFF007AFF);
  static const appleBlueDark = Color(0xFF0056B3);
  static const appleGrayBg = Color(0xFFF5F5F7);
  static const appleGrayFill = Color(0xFFE8E8ED);
  static const appleGrayFill2 = Color(0xFFD1D1D6);
  static const appleText = Color(0xFF1D1D1F);
  static const appleTextSecondary = Color(0xFF86868B);
  static const appleSeparator = Color(0xFFD2D2D7);
  static const appleGreen = Color(0xFF34C759);
  static const appleOrange = Color(0xFFFF9500);
  static const appleRed = Color(0xFFFF3B30);
  static const applePurple = Color(0xFFAF52DE);

  // Spacing (8pt grid)
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;
  static const spaceXl = 24.0;

  // Radii
  static const radiusSm = 8.0;
  static const radiusMd = 10.0;
  static const radiusLg = 12.0;
  static const radiusPill = 20.0;

  // Layout
  static const groupPanelDefaultWidth = 260.0;
  static const groupPanelMinWidth = 180.0;
  static const groupPanelMaxWidth = 480.0;
  static const groupPanelCollapsedWidth = 44.0;
  static const splitHandleWidth = 6.0;

  static Color levelColor(String level) {
    final normalized = level.toLowerCase();
    if (normalized.contains('error') || normalized.contains('fatal')) {
      return appleRed;
    }
    if (normalized.contains('warn')) return appleOrange;
    if (normalized.contains('debug') || normalized.contains('verbose')) {
      return applePurple;
    }
    return appleGreen;
  }

  static BoxDecoration surfaceCard(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static InputDecoration inputDecoration({
    required BuildContext context,
    required String label,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: appleBlue, width: 1.5),
      ),
      suffixIcon: suffixIcon,
    );
  }
}