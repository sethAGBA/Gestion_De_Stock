// import 'dart:io';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:actis/helpers/database_helper.dart';
// import 'package:intl/intl.dart';

// class NotificationService {
//   static final NotificationService _notificationService = NotificationService._internal();
//   final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

//   factory NotificationService() {
//     return _notificationService;
//   }

//   NotificationService._internal();

//   Future<void> initialize() async {
//      const AndroidInitializationSettings initializationSettingsAndroid = 
//         AndroidInitializationSettings('@android:drawable/ic_dialog_info');
    
//     const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
//     const InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsDarwin,
//     );

//     await _notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) async {
//         if (response.payload != null) {
//           print('Notification tapped with payload: ${response.payload}');
//         }
//       },
//     );

//     // Request permissions for Android 13+ and iOS
//     if (Platform.isAndroid) {
//       final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//       await androidPlugin?.requestNotificationsPermission();
//       // Request exact alarm permission
//       final bool? exactAlarmGranted = await androidPlugin?.requestExactAlarmsPermission();
//       print('Exact alarm permission granted: $exactAlarmGranted');
//     } else if (Platform.isIOS) {
//       final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
//       await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
//     }
//   }

//   Future<void> scheduleDailyNotifications() async {
//     // Cancel existing notifications to avoid duplicates
//     await _notificationsPlugin.cancelAll();

//     final now = DateTime.now();
//     final birthdays = await DatabaseHelper().getUpcomingBirthdays();
//     final orders = await DatabaseHelper().getUpcomingOrders();

//     // Schedule notifications at 8:00 AM and 4:00 PM
//     final nowTz = tz.TZDateTime.now(tz.local);
//     final times = [
//       tz.TZDateTime(tz.local, nowTz.year, nowTz.month, nowTz.day, 8, 0),
//       tz.TZDateTime(tz.local, nowTz.year, nowTz.month, nowTz.day, 16, 0),
//     ];

//     for (final scheduledTime in times) {
//       await _scheduleNotificationAt(scheduledTime, birthdays, orders);
//     }
//   }

//   Future<void> _scheduleNotificationAt(
//     tz.TZDateTime scheduledTime,
//     List<Map<String, dynamic>> birthdays,
//     List<Map<String, dynamic>> orders,
//   ) async {
//     final now = DateTime.now();
//     if (scheduledTime.isBefore(now)) {
//       scheduledTime = scheduledTime.add(const Duration(days: 1));
//     }

//     final birthdayMessages = <String>[];
//     for (final birthday in birthdays) {
//       final birthdateStr = birthday['birthdate'].toString().trim();
//       if (birthdateStr.isEmpty) continue;
//       try {
//         final birthdate = DateFormat('d/M/yyyy').parseStrict(birthdateStr);
//         final nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
//         final daysUntilBirthday = birthday['daysUntil'] ?? (nextBirthday.isBefore(now)
//             ? nextBirthday.add(const Duration(days: 365)).difference(now).inDays
//             : nextBirthday.difference(now).inDays);
//         if (daysUntilBirthday <= 30) {
//           final daysText = daysUntilBirthday == 0 ? 'aujourd\'hui' : 'dans $daysUntilBirthday jours';
//           birthdayMessages.add('${birthday['name']} $daysText');
//         }
//       } catch (e) {
//         print('Error parsing birthdate for ${birthday['name']}: $e, birthdate: $birthdateStr');
//       }
//     }

//     final orderMessages = <String>[];
//     for (final order in orders) {
//       final deliveryDateStr = order['deliveryDate'].toString().trim();
//       try {
//         final deliveryDate = DateTime.parse(deliveryDateStr);
//         final daysUntilDelivery = deliveryDate.difference(now).inDays;
//         if (daysUntilDelivery <= 7 && daysUntilDelivery >= 0) {
//           final client = await DatabaseHelper().getClientById(order['clientId']);
//           final formattedDate = DateFormat('dd/MM/yyyy').format(deliveryDate);
//           if (client != null && client['name'] != null) {
//             orderMessages.add('${client['name']} le $formattedDate');
//           } else {
//             orderMessages.add('Client inconnu le $formattedDate');
//           }
//         }
//       } catch (e) {
//         print('Error parsing delivery date for order: $e, deliveryDate: $deliveryDateStr');
//       }
//     }

//     String notificationBody = '';
//     String payload = '';
//     if (birthdayMessages.isNotEmpty || orderMessages.isNotEmpty) {
//       if (birthdayMessages.isNotEmpty) {
//         notificationBody += 'Anniversaires à venir : ${birthdayMessages.join(', ')}\n';
//         payload = '/clients';
//       }
//       if (orderMessages.isNotEmpty) {
//         notificationBody += 'Livraisons en attente : ${orderMessages.join(', ')}';
//         payload = '/orders';
//       }
//     } else {
//       notificationBody = 'Aucun rappel pour aujourd\'hui.';
//       payload = '/';
//     }

//     const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
//       'reminders_channel',
//       'Rappels',
//       channelDescription: 'Notifications pour anniversaires et livraisons',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//     const NotificationDetails notificationDetails = NotificationDetails(
//       android: androidNotificationDetails,
//       iOS: DarwinNotificationDetails(),
//     );

//     // Check if exact alarms are permitted
//     final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//     final bool? canScheduleExact = await androidPlugin?.canScheduleExactNotifications();
//     final scheduleMode = (canScheduleExact ?? false) ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexact;

//     try {
//       await _notificationsPlugin.zonedSchedule(
//         scheduledTime.hashCode,
//         'Rappels Act.is',
//         notificationBody,
//         scheduledTime,
//         notificationDetails,
//         androidScheduleMode: scheduleMode,
//         payload: payload,
//       );
//       print('Scheduled notification at $scheduledTime with body: $notificationBody, mode: $scheduleMode');
//     } catch (e) {
//       print('Error scheduling notification: $e');
//     }
//   }
// }



import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:actis/helpers/database_helper.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Utilisation d'une icône par défaut ou aucune icône spécifiée
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@android:drawable/app_icon');
     // Utilisation d'une icône par défaut ou aucune icône spécifiée
    // const AndroidInitializationSettings initializationSettingsAndroid = 
        // AndroidInitializationSettings('@android:drawable/ic_dialog_info');
    
    const DarwinInitializationSettings initializationSettingsDarwin = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          if (response.payload != null) {
            print('Notification tapped with payload: ${response.payload}');
          }
        },
      );

      // Demander les permissions pour Android 13+ et iOS
      await _requestPermissions();
      
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Demander la permission de notification
        final bool? granted = await androidPlugin.requestNotificationsPermission();
        print('Notification permission granted: $granted');
        
        // Demander la permission pour les alarmes exactes
        final bool? exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
        print('Exact alarm permission granted: $exactAlarmGranted');
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        final bool? granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('iOS notification permissions granted: $granted');
      }
    }
  }

  Future<void> scheduleDailyNotifications() async {
    try {
      // Annuler les notifications existantes pour éviter les doublons
      await _notificationsPlugin.cancelAll();
      print('Previous notifications cancelled');

      final now = DateTime.now();
      final birthdays = await DatabaseHelper().getUpcomingBirthdays();
      final orders = await DatabaseHelper().getUpcomingOrders();

      // Programmer les notifications à 8h00 et 16h00
      final nowTz = tz.TZDateTime.now(tz.local);
      final times = [
        tz.TZDateTime(tz.local, nowTz.year, nowTz.month, nowTz.day, 8, 0),
        tz.TZDateTime(tz.local, nowTz.year, nowTz.month, nowTz.day, 16, 0),
      ];

      for (int i = 0; i < times.length; i++) {
        await _scheduleNotificationAt(times[i], birthdays, orders, i);
      }
      
      print('Daily notifications scheduled successfully');
    } catch (e) {
      print('Error scheduling daily notifications: $e');
    }
  }

  Future<void> _scheduleNotificationAt(
    tz.TZDateTime scheduledTime,
    List<Map<String, dynamic>> birthdays,
    List<Map<String, dynamic>> orders,
    int timeIndex,
  ) async {
    try {
      final now = DateTime.now();
      
      // Si l'heure est déjà passée aujourd'hui, programmer pour demain
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final birthdayMessages = <String>[];
      for (final birthday in birthdays) {
        final birthdateStr = birthday['birthdate']?.toString()?.trim() ?? '';
        if (birthdateStr.isEmpty) continue;
        
        try {
          final birthdate = DateFormat('d/M/yyyy').parseStrict(birthdateStr);
          final nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
          final daysUntilBirthday = birthday['daysUntil'] ?? 
              (nextBirthday.isBefore(now)
                  ? nextBirthday.add(const Duration(days: 365)).difference(now).inDays
                  : nextBirthday.difference(now).inDays);
          
          if (daysUntilBirthday <= 30) {
            final daysText = daysUntilBirthday == 0 
                ? 'aujourd\'hui' 
                : 'dans $daysUntilBirthday jour${daysUntilBirthday > 1 ? 's' : ''}';
            birthdayMessages.add('${birthday['name']} $daysText');
          }
        } catch (e) {
          print('Error parsing birthdate for ${birthday['name']}: $e, birthdate: $birthdateStr');
        }
      }

      final orderMessages = <String>[];
      for (final order in orders) {
        final deliveryDateStr = order['deliveryDate']?.toString()?.trim() ?? '';
        if (deliveryDateStr.isEmpty) continue;
        
        try {
          final deliveryDate = DateTime.parse(deliveryDateStr);
          final daysUntilDelivery = deliveryDate.difference(now).inDays;
          
          if (daysUntilDelivery <= 7 && daysUntilDelivery >= 0) {
            final client = await DatabaseHelper().getClientById(order['clientId']);
            final formattedDate = DateFormat('dd/MM/yyyy').format(deliveryDate);
            
            if (client != null && client['name'] != null) {
              orderMessages.add('${client['name']} le $formattedDate');
            } else {
              orderMessages.add('Client inconnu le $formattedDate');
            }
          }
        } catch (e) {
          print('Error parsing delivery date for order: $e, deliveryDate: $deliveryDateStr');
        }
      }

      String notificationTitle = 'Rappels Act.is';
      String notificationBody = '';
      String payload = '/';

      if (birthdayMessages.isNotEmpty || orderMessages.isNotEmpty) {
        List<String> bodyParts = [];
        
        if (birthdayMessages.isNotEmpty) {
          bodyParts.add('🎂 Anniversaires : ${birthdayMessages.join(', ')}');
          payload = '/clients';
        }
        
        if (orderMessages.isNotEmpty) {
          bodyParts.add('📦 Livraisons : ${orderMessages.join(', ')}');
          if (payload == '/') payload = '/orders';
        }
        
        notificationBody = bodyParts.join('\n');
      } else {
        notificationBody = 'Aucun rappel pour aujourd\'hui.';
      }

      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'reminders_channel',
        'Rappels Act.is',
        channelDescription: 'Notifications pour anniversaires et livraisons',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Vérifier si les alarmes exactes sont autorisées
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? canScheduleExact = await androidPlugin?.canScheduleExactNotifications();
      final scheduleMode = (canScheduleExact ?? false) 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexact;

      // Créer un ID unique pour chaque notification
      final notificationId = scheduledTime.hashCode + timeIndex;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationBody,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        payload: payload,
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('Scheduled notification at $scheduledTime with body: $notificationBody, mode: $scheduleMode');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Méthode pour annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }

  // Méthode pour vérifier si les notifications sont activées
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions() ?? false;
    }
    return false;
  }
}