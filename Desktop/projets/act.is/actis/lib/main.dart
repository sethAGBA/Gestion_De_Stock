// import 'package:flutter/material.dart';
// import 'app.dart';

// void main() {
//   runApp(const ActisApp());
// }


// import 'package:flutter/material.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:actis/notifications/notification_service.dart';
// import 'app.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await initializeDateFormatting('fr_FR', null);
//   await NotificationService.initialize();
//   runApp(const ActisApp());
// }


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:actis/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'app.dart';

final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await _configureLocalTimeZone();
//   await initializeDateFormatting('fr_FR', null);
//   await NotificationService().initialize();
//   runApp(const ActisApp());
// }



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _configureLocalTimeZone();
    await initializeDateFormatting('fr_FR', null);
    await NotificationService().initialize();
    runApp(const ActisApp());
  } catch (e, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Erreur au démarrage : $e')),
      ),
    ));
    print('Erreur au démarrage : $e\n$stack');
  }
}