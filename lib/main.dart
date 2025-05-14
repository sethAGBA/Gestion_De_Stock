import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  // Obtenir la taille de l'écran principal
  final screen = await windowManager.getBounds();
  final screenSize = screen.size;

  // Définir une taille par défaut relative (80% de l'écran)
  final double defaultWidth = screenSize.width * 0.8;
  final double defaultHeight = screenSize.height * 0.8;

  WindowOptions windowOptions = WindowOptions(
    size: Size(defaultWidth, defaultHeight),
    minimumSize: const Size(1000, 700), // Taille minimale imposée
    center: true,
    title: "Gestion de Stock",
    backgroundColor: Colors.white,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const StockManagementApp());
}

class StockManagementApp extends StatelessWidget {
  const StockManagementApp({Key? key}) : super(key: key);

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
      home: const DashboardScreen(),
    );
  }
}