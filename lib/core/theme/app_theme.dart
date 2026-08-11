import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Telegram color palette
  static const Color tgBlue = Color(0xFF2AABEE);
  static const Color tgDarkBlue = Color(0xFF1C92D2);
  static const Color tgBackground = Color(0xFFFFFFFF);
  static const Color tgSecondaryBg = Color(0xFFF1F1F1);
  static const Color tgSurface = Color(0xFFFFFFFF);
  static const Color tgDivider = Color(0xFFE8E8E8);
  static const Color tgGrey = Color(0xFF8D8D93);
  static const Color tgGreen = Color(0xFF4CAF50);
  static const Color tgRed = Color(0xFFE53935);
  static const Color tgOutgoingBubble = Color(0xFFEFFAE1);
  static const Color tgIncomingBubble = Color(0xFFFFFFFF);
  static const Color tgPinnedBg = Color(0xFFF4F4F5);

  // Dark theme colors
  static const Color tgDarkBg = Color(0xFF212121);
  static const Color tgDarkSurface = Color(0xFF2C2C2E);
  static const Color tgDarkSecondaryBg = Color(0xFF1C1C1E);
  static const Color tgDarkDivider = Color(0xFF3A3A3C);
  static const Color tgDarkGrey = Color(0xFF8D8D93);
  static const Color tgDarkOutgoingBubble = Color(0xFF2B5278);
  static const Color tgDarkIncomingBubble = Color(0xFF1C2733);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: tgBlue,
          secondary: tgDarkBlue,
          surface: tgSurface,
          onPrimary: Colors.white,
          onSurface: Color(0xFF000000),
        ),
        scaffoldBackgroundColor: tgBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: tgBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
        dividerTheme: const DividerThemeData(
          color: tgDivider,
          thickness: 0.5,
          space: 0,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: tgSurface,
          selectedItemColor: tgBlue,
          unselectedItemColor: tgGrey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintStyle: GoogleFonts.roboto(color: tgGrey, fontSize: 16),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: tgBlue,
          foregroundColor: Colors.white,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: tgBlue,
          secondary: tgDarkBlue,
          surface: tgDarkSurface,
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: tgDarkBg,
        appBarTheme: AppBarTheme(
          backgroundColor: tgDarkSurface,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        dividerTheme: const DividerThemeData(
          color: tgDarkDivider,
          thickness: 0.5,
          space: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: tgDarkSurface,
          selectedItemColor: tgBlue,
          unselectedItemColor: tgDarkGrey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintStyle: GoogleFonts.roboto(color: tgDarkGrey, fontSize: 16),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: tgBlue,
          foregroundColor: Colors.white,
        ),
      );
}
