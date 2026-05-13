import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // FCM handles background notifications automatically.
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'messages_channel';
  static const _channelName = 'Berichten';
  static const _channelDesc = 'Notificaties voor nieuwe chatberichten';

  /// Call this in main() before runApp().
  /// Only sets up the plugin and channel — does NOT request permission yet
  /// (the Activity is not visible yet at that point).
  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Create high-importance notification channel (Android 8+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Register FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Show local notification for FCM messages that arrive while app is open
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

  /// Call this once the app's UI is visible (e.g. from BottomNavScreen.initState).
  /// Shows the system permission dialog on Android 13+ and requests FCM token.
  static Future<void> requestPermissions() async {
    // Android 13+ local notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // FCM permission (iOS + Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
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
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
    );
    await _plugin.show(id, title, body, details);
  }
}
