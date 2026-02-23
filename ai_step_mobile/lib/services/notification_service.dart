import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Use @mipmap/ic_launcher which is the default app icon
    const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request iOS permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showGoalAchievedNotification(int steps) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'step_goal_channel',
      'Step Goal Notifications',
      channelDescription: 'Notifications for step goals',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_launcher',
      showWhen: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        1,
        '🎉 Goal Achieved!',
        'You reached your daily goal of $steps steps!',
        notificationDetails,
      );
    } catch (e) {
      print('NotificationService.showGoalAchievedNotification: failed to show notification: $e');
    }
  }

  Future<void> showSyncErrorNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'sync_error_channel',
      'Sync Error Notifications',
      channelDescription: 'Notifications for sync errors',
      importance: Importance.low,
      priority: Priority.low,
      icon: 'ic_launcher',
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        2,
        'Sync Error',
        'Failed to sync steps with server. Will retry later.',
        notificationDetails,
      );
    } catch (e) {
      print('NotificationService.showSyncErrorNotification: failed to show notification: $e');
    }
  }
}
