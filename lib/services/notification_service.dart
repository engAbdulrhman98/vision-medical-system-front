import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vision_medical_system_app/services/db_helper.dart';

class NotificationService {
  // Singleton pattern
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    // The name matches 'launcher_icon' under android/app/src/main/res/mipmap-*/launcher_icon.png
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization settings (Darwin)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification click here if needed (e.g. navigate to a specific screen)
      },
    );

    _isInitialized = true;
  }

  /// Requests notification permissions for Android 13+ (API 33+) and iOS ONCE per app installation
  Future<void> requestPermissions() async {
    final requested = await ChatDatabaseHelper.instance.getFromCache('notification_permission_requested');
    if (requested == 'true') {
      return; // Already asked once after installation
    }

    await initialize();
    
    // Request for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // Request for iOS
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
            
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await ChatDatabaseHelper.instance.saveToCache('notification_permission_requested', 'true');
  }

  /// Displays a system notification outside the app with sound and heads-up banner
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'vision_medical_notifications_channel', // unique channel ID
      'Medical System Alerts', // channel name
      channelDescription: 'System warnings, new task assignments, and chat notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
