// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'theme/app_theme.dart';
// import 'pages/home_page.dart';
// import 'providers/theme_provider.dart';

// class ActisApp extends StatelessWidget {
//   const ActisApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => ThemeProvider(),
//       child: Consumer<ThemeProvider>(
//         builder: (context, themeProvider, child) {
//           return MaterialApp(
//             title: 'Act.is - Gestion Futuriste des Clients',
//             theme: AppTheme.lightTheme,
//             darkTheme: AppTheme.darkTheme,
//             themeMode: themeProvider.themeMode,
//             home: const HomePage(),
//           );
//         },
//       ),
//     );
//   }
// }



// import 'package:actis/providers/theme_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'theme/app_theme.dart';
// import 'pages/home_page.dart';
// import 'pages/add_client_page.dart';
// import 'pages/edit_client_page.dart';
// import 'pages/orders_page.dart';
// import 'pages/clients_page.dart'; // For Client class

// class ActisApp extends StatelessWidget {
//   const ActisApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => ThemeProvider(),
//       child: Consumer<ThemeProvider>(
//         builder: (context, themeProvider, child) {
//           return MaterialApp(
//             title: 'Act.is - Gestion Futuriste des Clients',
//             theme: AppTheme.lightTheme,
//             darkTheme: AppTheme.darkTheme,
//             themeMode: themeProvider.themeMode,
//             initialRoute: '/',
//             routes: {
//               '/': (context) => const HomePage(),
//               '/add_client': (context) => const AddClientPage(),
//               '/edit_client': (context) => EditClientPage(
//                     client: ModalRoute.of(context)!.settings.arguments as Client,
//                   ),
//               '/orders': (context) => OrdersPage(
//                     clientId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?)?['clientId'],
//                   ),
//             },
//             onUnknownRoute: (settings) {
//               return MaterialPageRoute(
//                 builder: (context) => Scaffold(
//                   appBar: AppBar(title: const Text('Erreur')),
//                   body: Center(
//                     child: Text('Route non trouvée: ${settings.name}'),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }





import 'package:actis/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/add_client_page.dart';
import 'pages/edit_client_page.dart';
import 'pages/orders_page.dart';
import 'pages/clients_page.dart';
import '../main.dart';

class ActisApp extends StatefulWidget {
  const ActisApp({super.key});

  @override
  State<ActisApp> createState() => _ActisAppState();
}

class _ActisAppState extends State<ActisApp> {
  String _initialRoute = '/';

  @override
  void initState() {
    super.initState();
    _checkNotificationLaunch();
    _configureSelectNotificationSubject();
  }

  Future<void> _checkNotificationLaunch() async {
    final notificationAppLaunchDetails =
        await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null && ['/clients', '/orders', '/'].contains(payload)) {
        setState(() {
          _initialRoute = payload;
        });
      }
    }
  }

  void _configureSelectNotificationSubject() {
    selectNotificationStream.stream.listen((NotificationResponse? response) async {
      if (response?.payload != null && mounted) {
        Navigator.of(context).pushNamed(response!.payload!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Act.is - Gestion Futuriste des Clients',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: _initialRoute,
            routes: {
              '/': (context) => const HomePage(),
              '/add_client': (context) => const AddClientPage(),
              '/edit_client': (context) => EditClientPage(
                    client: ModalRoute.of(context)!.settings.arguments as Client,
                  ),
              '/orders': (context) => OrdersPage(
                    clientId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?)?['clientId'],
                  ),
              '/clients': (context) => const ClientsPage(),
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Erreur')),
                  body: Center(
                    child: Text('Route non trouvée: ${settings.name}'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}