import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends ChangeNotifier {
  NotificationController._();

  static final NotificationController instance = NotificationController._();

  static const String _enabledKey = 'notifications_enabled';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _enabled = false;
  bool _ready = false;

  bool get enabled => _enabled;
  bool get ready => _ready;

  Future<void> get readyFuture => _initialize();

  Future<void> _initialize() async {
    if (_ready) return;

    final preferences = await SharedPreferences.getInstance();
    _enabled = preferences.getBool(_enabledKey) ?? false;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
    );

    _ready = true;
    notifyListeners();
  }

  Future<bool> setEnabled(bool value) async {
    if (!_ready) {
      await _initialize();
    }

    if (value) {
      final permissionGranted = await _requestPermission();

      if (!permissionGranted) {
        return false;
      }
    } else {
      await _plugin.cancelAll();
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, value);

    _enabled = value;
    notifyListeners();

    return true;
  }

  Future<bool> _requestPermission() async {
    if (kIsWeb) {
      final webPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin>();

      if (webPlugin == null) {
        return false;
      }

      final permission = await webPlugin.requestNotificationsPermission();

      return permission ?? false;
    }

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) {
      return false;
    }

    final permission =
        await androidImplementation.requestNotificationsPermission();

    return permission ?? false;
  }

  Future<void> showTestNotification() async {
    if (!_enabled) return;

    if (kIsWeb) {
      final webPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin>();

      await webPlugin?.show(
        id: 1,
        title: 'Cloud Guard',
        body: 'Notifications are working successfully.',
      );

      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'cloud_guard_notifications',
      'Cloud Guard Notifications',
      channelDescription: 'Notifications from Cloud Guard',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id: 1,
      title: 'Cloud Guard',
      body: 'Notifications are working successfully.',
      notificationDetails: notificationDetails,
    );
  }
}

final notificationController = NotificationController.instance;