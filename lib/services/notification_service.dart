import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // FCM handles background notifications automatically
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'messages_channel';
  static const _channelName = 'Berichten';
  static const _channelDesc = 'Notificaties voor nieuwe chatberichten';

  static Future<void> initialize() async {
    // Android local notifications setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Create high-importance notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request FCM permission (iOS + Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show local notification when FCM message arrives in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) {
        showNotification(
          id: message.hashCode,
          title: n.title ?? 'Nieuw bericht',
          body: n.body ?? '',
        );
      }
    });
  }

  static Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  static Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String messageText,
  }) =>
      showNotification(id: id, title: senderName, body: messageText);

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id, title, body, details);
  }
}
