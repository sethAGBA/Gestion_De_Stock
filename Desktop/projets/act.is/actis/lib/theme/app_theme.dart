// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class AppTheme {
//   static final ThemeData lightTheme = ThemeData(
//     primaryColor: const Color(0xFF00DDEB),
//     scaffoldBackgroundColor: const Color(0xFFF5F7FA),
//     fontFamily: GoogleFonts.orbitron().fontFamily,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: const Color(0xFF00DDEB),
//       background: const Color(0xFFF5F7FA),
//       primary: const Color(0xFF00DDEB),
//       secondary: const Color(0xFF8B00FF),
//       brightness: Brightness.light,
//     ),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       centerTitle: true,
//       foregroundColor: Color(0xFF0A0E21),
//     ),
//     bottomNavigationBarTheme: BottomNavigationBarThemeData(
//       type: BottomNavigationBarType.fixed,
//       backgroundColor: Colors.white.withOpacity(0.9),
//       selectedItemColor: const Color(0xFF00DDEB),
//       unselectedItemColor: const Color(0xFF0A0E21).withOpacity(0.6),
//       selectedLabelStyle: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//       unselectedLabelStyle: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//       elevation: 0,
//     ),
//     cardTheme: CardThemeData(
//       elevation: 2,
//       color: Colors.white.withOpacity(0.95),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xFF00DDEB),
//         foregroundColor: Colors.black,
//         minimumSize: const Size(double.infinity, 48),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 0,
//       ),
//     ),
//     floatingActionButtonTheme: const FloatingActionButtonThemeData(
//       backgroundColor: Color(0xFF8B00FF),
//       foregroundColor: Colors.white,
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0xFF00DDEB), width: 2),
//       ),
//       labelStyle: TextStyle(color: Colors.grey[600]),
//     ),
//     textTheme: TextTheme(
//       headlineMedium: TextStyle(
//         color: const Color(0xFF0A0E21),
//         fontSize: 24,
//         fontWeight: FontWeight.bold,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//       bodyMedium: TextStyle(
//         color: const Color(0xFF0A0E21).withOpacity(0.8),
//         fontSize: 16,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//       titleLarge: TextStyle(
//         color: const Color(0xFF0A0E21),
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//     ),
//   );

//   static final ThemeData darkTheme = ThemeData(
//     primaryColor: const Color(0xFF00DDEB),
//     scaffoldBackgroundColor: const Color(0xFF0A0E21),
//     fontFamily: GoogleFonts.orbitron().fontFamily,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: const Color(0xFF00DDEB),
//       background: const Color(0xFF0A0E21),
//       primary: const Color(0xFF00DDEB),
//       secondary: const Color(0xFF8B00FF),
//       brightness: Brightness.dark,
//     ),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       centerTitle: true,
//       foregroundColor: Colors.white,
//     ),
//     bottomNavigationBarTheme: BottomNavigationBarThemeData(
//       type: BottomNavigationBarType.fixed,
//       backgroundColor: Colors.black.withOpacity(0.3),
//       selectedItemColor: const Color(0xFF00DDEB),
//       unselectedItemColor: Colors.white60,
//       selectedLabelStyle: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//       unselectedLabelStyle: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//       elevation: 0,
//     ),
//     cardTheme: CardThemeData(
//       elevation: 0,
//       color: Colors.white.withOpacity(0.1),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xFF00DDEB),
//         foregroundColor: Colors.black,
//         minimumSize: const Size(double.infinity, 48),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 0,
//       ),
//     ),
//     floatingActionButtonTheme: const FloatingActionButtonThemeData(
//       backgroundColor: Color(0xFF8B00FF),
//       foregroundColor: Colors.white,
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0xFF00DDEB), width: 2),
//       ),
//       labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
//     ),
//     textTheme: TextTheme(
//       headlineMedium: TextStyle(
//         color: Colors.white,
//         fontSize: 24,
//         fontWeight: FontWeight.bold,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//       bodyMedium: TextStyle(
//         color: Colors.white70,
//         fontSize: 16,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//       titleLarge: TextStyle(
//         color: Colors.white,
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         fontFamily: GoogleFonts.orbitron().fontFamily,
//       ),
//     ),
//   );
// }




// // GoogleFonts.roboto()
// // GoogleFonts.poppins()
// // GoogleFonts.orbitron()


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF006633),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    fontFamily: GoogleFonts.poppins().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF006633),
      background: const Color(0xFFF5F7FA),
      primary: const Color(0xFF006633),
      secondary: const Color(0xFF99CC99),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Color(0xFF0A0E21),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white.withOpacity(0.9),
      selectedItemColor: const Color(0xFF66CC66),
      unselectedItemColor: const Color(0xFF0A0E21).withOpacity(0.6),
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006633),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF99CC99),
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF66CC66), width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey[600]),
    ),
    textTheme: TextTheme(
      headlineMedium: const TextStyle(
        color: Color(0xFF0A0E21),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Gilroy',
      ),
      bodyMedium: TextStyle(
        color: const Color(0xFF0A0E21).withOpacity(0.8),
        fontSize: 16,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      titleLarge: const TextStyle(
        color: Color(0xFF0A0E21),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Gilroy',
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color(0xFF006633),
    scaffoldBackgroundColor: const Color(0xFF0A0E21),
    fontFamily: GoogleFonts.poppins().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF006633),
      background: const Color(0xFF0A0E21),
      primary: const Color(0xFF006633),
      secondary: const Color(0xFF99CC99),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black.withOpacity(0.3),
      selectedItemColor: const Color(0xFF66CC66),
      unselectedItemColor: Colors.white60,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006633),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF99CC99),
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF66CC66), width: 2),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    ),
    textTheme: TextTheme(
      headlineMedium: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Gilroy',
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      titleLarge: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Gilroy',
      ),
    ),
  );
}