// import 'package:flutter/material.dart';
// import 'package:window_manager/window_manager.dart';

// import 'screens/dashboard_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await windowManager.ensureInitialized();

//   // Obtenir la taille de l'écran principal
//   final screen = await windowManager.getBounds();
//   final screenSize = screen.size;

//   // Définir une taille par défaut relative (80% de l'écran)
//   final double defaultWidth = screenSize.width * 0.8;
//   final double defaultHeight = screenSize.height * 0.8;

//   WindowOptions windowOptions = WindowOptions(
//     size: Size(defaultWidth, defaultHeight),
//     minimumSize: const Size(1000, 700), // Taille minimale imposée
//     center: true,
//     title: "Gestion de Stock",
//     backgroundColor: Colors.white,
//   );

//   windowManager.waitUntilReadyToShow(windowOptions, () async {
//     await windowManager.show();
//     await windowManager.focus();
//   });

//   runApp(const StockManagementApp());
// }

// class StockManagementApp extends StatelessWidget {
//   const StockManagementApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Gestion de Stock',
//       theme: ThemeData(
//         primaryColor: const Color(0xFF1C3144),
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF1C3144),
//           primary: const Color(0xFF1C3144),
//         ),
//         useMaterial3: true,
//       ),
//       home: const DashboardScreen(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(1000, 700),
      center: true,
      title: 'Gestion de Stock',
      backgroundColor: Colors.white,
    );

    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.show();
    await windowManager.focus();
  } catch (e) {
    debugPrint('Erreur window_manager: $e');
    // Continue même si window_manager échoue
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: const StockManagementApp(),
    ),
  );
}

class StockManagementApp extends StatelessWidget {
  const StockManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion de Stock',
      theme: ThemeData(
        primaryColor: const Color(0xFF1C3144),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C3144),
          primary: const Color(0xFF1C3144),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Consumer<AuthProvider>(
              builder: (context, auth, _) => auth.isAuthenticated 
                  ? const DashboardScreen() 
                  : const LoginScreen(),
            ),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}