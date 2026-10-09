import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bundled brand font (assets/fonts).
const kFontFamily = 'PlusJakartaSans';

/// Transparent status bar with light icons, for the blue headers.
const appOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

/// LearnHub's white-and-blue palette.
class AppColors {
  static const primary = Color(0xFF1F64C8);
  static const primaryDark = Color(0xFF123F86);
  static const primaryBright = Color(0xFF3B82F6);
  static const tint = Color(0xFFE9F1FD);
  static const background = Color(0xFFF3F6FB);
  static const border = Color(0xFFDDE6F3);
  static const ink = Color(0xFF132238);
  static const muted = Color(0xFF6A7A92);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB7791F);
  static const danger = Color(0xFFC0392B);
  static const teal = Color(0xFF0E7490);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryBright],
    stops: [0, 0.55, 1],
  );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary)
      .copyWith(surface: Colors.white, onSurface: AppColors.ink);
  final radius = BorderRadius.circular(12);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color, width: width));
  bool selected(Set<WidgetState> s) => s.contains(WidgetState.selected);

  return ThemeData(
    colorScheme: scheme,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: appOverlayStyle,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: kFontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      titleTextStyle: TextStyle(fontFamily: kFontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
      subtitleTextStyle: TextStyle(fontFamily: kFontFamily, fontSize: 12.5, color: AppColors.muted, height: 1.35),
      iconColor: AppColors.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(fontFamily: kFontFamily, color: AppColors.muted),
      hintStyle: TextStyle(fontFamily: kFontFamily, color: AppColors.muted.withValues(alpha: 0.7)),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      disabledBorder: border(AppColors.border.withValues(alpha: 0.6)),
      focusedBorder: border(AppColors.primary, 1.6),
      errorBorder: border(Colors.red.shade300),
      focusedErrorBorder: border(Colors.red.shade400, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.tint,
      showCheckmark: false,
      shape: const StadiumBorder(),
      side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
            color: selected(s) ? AppColors.primary : AppColors.border,
            width: selected(s) ? 1.4 : 1,
          )),
      labelStyle: const TextStyle(fontFamily: kFontFamily, color: AppColors.ink, fontWeight: FontWeight.w500),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: AppColors.tint,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: selected(s) ? AppColors.primary : AppColors.muted)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(fontFamily: kFontFamily, 
            fontSize: 11.5,
            fontWeight: selected(s) ? FontWeight.w700 : FontWeight.w500,
            color: selected(s) ? AppColors.primary : AppColors.muted,
          )),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 24),
  );
}
