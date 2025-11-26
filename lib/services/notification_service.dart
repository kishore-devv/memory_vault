// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// class NotificationService {
//   final _local = FlutterLocalNotificationsPlugin();

//   Future<void> init() async {
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosInit = DarwinInitializationSettings();
//     await _local.initialize(
//       InitializationSettings(android: androidInit, iOS: iosInit),
//       onDidReceiveNotificationResponse: (payload) {
//         // handle tap
//       },
//     );

//     // FCM token registration to Supabase later:
//     FirebaseMessaging.instance.getToken().then((token) {
//       // save token to your supabase user's metadata table or profile
//     });

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       // Show local notification or handle in-app
//     });
//   }

//   Future<void> scheduleNotification(String id, String title, String body, DateTime dt) async {
//     await _local.zonedSchedule(
//       id.hashCode,
//       title,
//       body,
//       tz.TZDateTime.from(dt, tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails('reminders', 'Reminders'),
//       ),
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }
// }
