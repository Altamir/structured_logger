import 'package:flutter/material.dart';

import 'clef_design_system.dart';

ThemeData buildClefTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: ClefDs.appleBlue,
    onPrimary: Colors.white,
    secondary: ClefDs.appleTextSecondary,
    onSecondary: Colors.white,
    error: ClefDs.appleRed,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: ClefDs.appleText,
    onSurfaceVariant: ClefDs.appleTextSecondary,
    outline: ClefDs.appleSeparator,
    outlineVariant: ClefDs.appleGrayFill2,
    surfaceContainerHighest: ClefDs.appleGrayFill,
    surfaceContainerHigh: ClefDs.appleGrayBg,
    surfaceContainer: ClefDs.appleGrayBg,
    tertiary: ClefDs.appleBlue,
    onTertiary: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ClefDs.appleGrayBg,
    dividerColor: ClefDs.appleSeparator,
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: ClefDs.appleText,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: ClefDs.appleText,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClefDs.radiusLg),
        side: BorderSide(
          color: ClefDs.appleSeparator.withValues(alpha: 0.6),
        ),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: ClefDs.spaceSm,
        vertical: ClefDs.spaceXs,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ClefDs.appleBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClefDs.radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ClefDs.appleBlue,
        side: const BorderSide(color: ClefDs.appleSeparator),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClefDs.radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ClefDs.appleGrayFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClefDs.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClefDs.radiusMd),
        borderSide: BorderSide(
          color: ClefDs.appleSeparator.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClefDs.radiusMd),
        borderSide: const BorderSide(color: ClefDs.appleBlue, width: 1.5),
      ),
      labelStyle: const TextStyle(
        color: ClefDs.appleTextSecondary,
        fontSize: 13,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ClefDs.appleGrayFill,
      selectedColor: ClefDs.appleBlue.withValues(alpha: 0.15),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ClefDs.appleText,
      ),
      secondaryLabelStyle: const TextStyle(fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClefDs.radiusPill),
        side: BorderSide(
          color: ClefDs.appleSeparator.withValues(alpha: 0.5),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClefDs.radiusMd),
      ),
      backgroundColor: ClefDs.appleText,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: ClefDs.spaceMd),
      minVerticalPadding: 4,
    ),
    textTheme: const TextTheme(
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ClefDs.appleText,
        letterSpacing: -0.3,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: ClefDs.appleText,
        height: 1.35,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: ClefDs.appleTextSecondary,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        color: ClefDs.appleTextSecondary,
        letterSpacing: 0.1,
      ),
    ),
    iconTheme: const IconThemeData(
      size: 20,
      color: ClefDs.appleTextSecondary,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClefDs.radiusMd),
          ),
        ),
      ),
    ),
  );
}