import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/providers/ProductsProvider.dart';
import 'package:window_manager/window_manager.dart';
import 'helpers/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/employee_dashboard_screen.dart';
import 'screens/users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Stock Management',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  print('Initializing database...');
  await DatabaseHelper.database;
  await DatabaseHelper.debugDatabaseState();
  print('Resetting admin password...');
  await DatabaseHelper.resetAdminPassword();
  print('Debugging users...');
  await DatabaseHelper.debugUsers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
      ],
      child: MaterialApp(
        title: 'Stock Management',
        theme: ThemeData(
          primaryColor: const Color(0xFF1C3144),
          scaffoldBackgroundColor: Colors.grey.shade100,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1C3144),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C3144),
              foregroundColor: Colors.white,
            ),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/employee_dashboard': (context) => const EmployeeDashboardScreen(),
          '/users': (context) => const UsersScreen(),
        },
      ),
    );
  }
}