import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'helpers/database_helper.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final screen = await windowManager.getBounds();
  final screenSize = screen.size;
  final double defaultWidth = screenSize.width * 0.8;
  final double defaultHeight = screenSize.height * 0.8;

  WindowOptions windowOptions = WindowOptions(
    size: Size(defaultWidth, defaultHeight),
    minimumSize: const Size(1000, 700),
    center: true,
    title: "Gestion de Stock",
    backgroundColor: Colors.white,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await DatabaseHelper.checkAndInitializeData();
  runApp(const StockManagementApp());
}

class StockManagementApp extends StatelessWidget {
  const StockManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
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
        home: const LoginScreen(),
      ),
    );
  }
}