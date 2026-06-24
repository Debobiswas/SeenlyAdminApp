import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0066FF), // A sharp, clean blue
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE5F0FF), // Very light blue for subtle accents
      onPrimaryContainer: Color(0xFF001A40),
      secondary: Color(0xFF3385FF),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEBF3FF),
      onSecondaryContainer: Color(0xFF002255),
      tertiary: Color(0xFF66A3FF),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF0F6FF),
      onTertiaryContainer: Color(0xFF002B66),
      error: Color(0xFFDC362E),
      onError: Colors.white,
      errorContainer: Color(0xFFFCEEEE),
      onErrorContainer: Color(0xFF410E0B),
      surface: Colors.white, // Pure white for the scaffold background
      onSurface: Color(0xFF111827), // Dark grey for text
      surfaceContainerHighest: Color(0xFFFFFFFF), // Pure white for cards/surfaces
      onSurfaceVariant: Color(0xFF4B5563), // Medium grey for secondary text
      outline: Color(0xFFD1D5DB), // Light grey for borders
      outlineVariant: Color(0xFFE5E7EB), // Lighter grey for subtle dividers
      shadow: Color(0xFF000000), // Pure black for shadows (we control alpha in CardTheme)
      scrim: Color(0x99000000),
      inverseSurface: Color(0xFF1F2937),
      onInverseSurface: Color(0xFFF9FAFB),
      inversePrimary: Color(0xFF99C2FF),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF66A3FF), // Bright blue for visibility in dark mode
      onPrimary: Color(0xFF001A40),
      primaryContainer: Color(0xFF003380), // Deep blue for accents
      onPrimaryContainer: Color(0xFFE5F0FF),
      secondary: Color(0xFF99C2FF),
      onSecondary: Color(0xFF002255),
      secondaryContainer: Color(0xFF0044AA),
      onSecondaryContainer: Color(0xFFEBF3FF),
      tertiary: Color(0xFFB3D1FF),
      onTertiary: Color(0xFF002B66),
      tertiaryContainer: Color(0xFF0055CC),
      onTertiaryContainer: Color(0xFFF0F6FF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF111827), // Deep neutral gray for background
      onSurface: Color(0xFFF9FAFB), // Off-white for primary text
      surfaceContainerHighest: Color(0xFF1F2937), // Lighter gray for cards
      onSurfaceVariant: Color(0xFF9CA3AF), // Muted gray for secondary text
      outline: Color(0xFF4B5563),
      outlineVariant: Color(0xFF374151),
      shadow: Colors.black,
      scrim: Color(0xCC000000),
      inverseSurface: Color(0xFFF9FAFB),
      onInverseSurface: Color(0xFF111827),
      inversePrimary: Color(0xFF0066FF),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
        displayMedium: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineLarge: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 8,
        color: colorScheme.brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.85)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: _inputBorder(colorScheme.outlineVariant),
        enabledBorder: _inputBorder(colorScheme.outlineVariant),
        focusedBorder: _inputBorder(colorScheme.primary, width: 1.8),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: Colors.transparent,
        unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
