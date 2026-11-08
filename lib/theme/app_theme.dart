import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B4332);
  static const Color primaryLight = Color(0xFF2D6A4F);
  static const Color primaryDark = Color(0xFF122F23);
  static const Color accent = Color(0xFFE0A52B);
  static const Color accentDark = Color(0xFF8A5E12);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFDFCF8);
  static const Color surfaceVariant = Color(0xFFF3F0E8);
  static const Color error = Color(0xFFC94343);
  static const Color success = Color(0xFF2D6A4F);
  static const Color terracotta = Color(0xFFB35C44);
  static const Color warning = Color(0xFF8A6500);
  static const Color textPrimary = Color(0xFF183326);
  static const Color textSecondary = Color(0xFF718176);
  static const Color divider = Color(0xFFE1E9DF);
  static const Color verifiedBadge = Color(0xFF1976D2);
  static const Color featuredBadge = Color(0xFFF5B800);
  static const Color darkBackground = Color(0xFF101A14);
  static const Color darkSurface = Color(0xFF18251C);
  static const Color darkSurfaceVariant = Color(0xFF24352A);
  static const Color darkTextPrimary = Color(0xFFE8F1E9);
  static const Color darkTextSecondary = Color(0xFFB0BFB2);
  static const Color darkDivider = Color(0xFF34463A);
}

class AppTheme {
  AppTheme._();

  static const systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.primary,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.primary,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final surface = isLight ? AppColors.surface : AppColors.darkSurface;
    final background =
        isLight ? AppColors.background : AppColors.darkBackground;
    final surfaceVariant =
        isLight ? AppColors.surfaceVariant : AppColors.darkSurfaceVariant;
    final textPrimary =
        isLight ? AppColors.textPrimary : AppColors.darkTextPrimary;
    final textSecondary =
        isLight ? AppColors.textSecondary : AppColors.darkTextSecondary;
    final divider = isLight ? AppColors.divider : AppColors.darkDivider;
    const primary = AppColors.primary;
    const primaryDark = AppColors.primaryDark;
    final accent = isLight ? AppColors.accentDark : AppColors.accent;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer:
          isLight ? const Color(0xFFE7EFE8) : const Color(0xFF174B2C),
      onPrimaryContainer:
          isLight ? AppColors.primaryDark : const Color(0xFFD1EBD5),
      secondary: accent,
      onSecondary: isLight ? AppColors.textPrimary : const Color(0xFF2B2100),
      secondaryContainer:
          isLight ? const Color(0xFFFFF1C2) : const Color(0xFF524200),
      onSecondaryContainer:
          isLight ? const Color(0xFF493800) : const Color(0xFFFFE69A),
      tertiary: AppColors.primaryLight,
      onTertiary: Colors.white,
      tertiaryContainer:
          isLight ? const Color(0xFFEAF4E9) : const Color(0xFF243F2A),
      onTertiaryContainer:
          isLight ? AppColors.primaryDark : const Color(0xFFD3E9D1),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer:
          isLight ? const Color(0xFFFFDAD6) : const Color(0xFF5C201E),
      onErrorContainer:
          isLight ? const Color(0xFF410002) : const Color(0xFFFFDAD6),
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: textSecondary,
      outline: divider,
      outlineVariant: divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isLight ? AppColors.darkSurface : AppColors.surface,
      onInverseSurface:
          isLight ? AppColors.darkTextPrimary : AppColors.textPrimary,
      inversePrimary: isLight ? AppColors.primaryLight : AppColors.primary,
      surfaceTint: primary,
    );
    final displayTheme = GoogleFonts.poppinsTextTheme();
    final bodyTheme = GoogleFonts.interTextTheme();

    final textTheme = bodyTheme.copyWith(
      displayLarge: displayTheme.displayLarge,
      displayMedium: displayTheme.displayMedium,
      displaySmall: displayTheme.displaySmall,
      headlineLarge: displayTheme.headlineLarge,
      headlineMedium: displayTheme.headlineMedium,
      headlineSmall: displayTheme.headlineSmall,
      titleLarge: displayTheme.titleLarge,
      titleMedium: displayTheme.titleMedium,
      titleSmall: displayTheme.titleSmall,
    );

    final resolvedTextTheme = textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 84,
        backgroundColor: AppColors.primary,
        indicatorColor: Colors.white.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : Colors.white,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => resolvedTextTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: primary),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: resolvedTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: resolvedTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemUiOverlayStyle,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: resolvedTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: divider.withValues(alpha: 0.7)),
        ),
        margin: const EdgeInsets.all(0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        side: BorderSide(color: divider),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: resolvedTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          side: BorderSide(color: primary),
          textStyle: resolvedTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: resolvedTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
        ),
        labelStyle: resolvedTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryLight.withValues(alpha: 0.45)
              : divider,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : textSecondary,
        ),
      ),
      dividerColor: divider,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle:
            resolvedTextTheme.bodyMedium?.copyWith(color: Colors.white),
        elevation: 8,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(color: divider),
    );
  }
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;
}

class AppRadius {
  AppRadius._();

  static const double card = 16;
  static const double chip = 20;
  static const double button = 12;
}

class AppShadow {
  AppShadow._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
}
