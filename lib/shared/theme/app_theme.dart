import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens e temas da linguagem visual do Notário.
/// Roxo é reservado a ações e foco; estados usam tons legíveis e consistentes.
class AppTheme {
  static const Color primaryColor = Color(0xFF6254C7);
  static const Color primaryDark = Color(0xFF4D429F);
  static const Color primaryLight = Color(0xFFECE9FA);
  static const Color successColor = Color(0xFF26734D);
  static const Color errorColor = Color(0xFFB33A3A);
  static const Color warningColor = Color(0xFF946200);
  static const Color infoColor = Color(0xFF35648A);
  static const Color prioridadeBaixa = infoColor;
  static const Color prioridadeMedia = warningColor;
  static const Color prioridadeAlta = errorColor;
  static const Color estadoPendente = Color(0xFF667085);
  static const Color estadoEmExecucao = primaryColor;
  static const Color estadoConcluida = successColor;
  static const Color estadoPulada = warningColor;
  static const Color estadoCancelada = errorColor;
  static const Color backgroundLight = Color(0xFFF7F7F5);
  static const Color backgroundDark = Color(0xFF151519);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF222228);
  static const Color borderLight = Color(0xFFE5E4E1);
  static const Color borderDark = Color(0xFF38383F);

  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? backgroundDark : backgroundLight;
    final surface = isDark ? surfaceDark : surfaceLight;
    final border = isDark ? borderDark : borderLight;
    final text = isDark ? const Color(0xFFF2F1F4) : const Color(0xFF222229);
    final muted = isDark ? const Color(0xFFB3B1BA) : const Color(0xFF686873);
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: isDark ? const Color(0xFFB5ACFF) : primaryColor,
      onPrimary: isDark ? const Color(0xFF211A56) : Colors.white,
      secondary: isDark ? const Color(0xFFB7B0D8) : const Color(0xFF68627C),
      error: isDark ? const Color(0xFFFFB4AB) : errorColor,
      surface: surface,
    );
    final baseText = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: text, displayColor: text);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: baseText.copyWith(
        headlineSmall:
            baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium:
            baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: baseText.bodyMedium?.copyWith(height: 1.4),
        bodySmall: baseText.bodySmall?.copyWith(color: muted, height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.primary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        indicatorColor: isDark ? const Color(0xFF383357) : primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
