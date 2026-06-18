import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_strings.dart';
import '../../models/food_item.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<String> _languageCode() async {
    final saved = await StorageService.instance.getString('app_locale');
    return saved == 'vi' ? 'vi' : 'en';
  }

  Future<bool> _hasAdvancedAlerts() async {
    final owned = await StorageService.instance.getStringList('pp_owned_items');
    return owned?.contains('feat_advanced_alerts') ?? false;
  }

  Future<void> scheduleExpiryAlerts(List<FoodItem> items) async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    final lang = await _languageCode();
    final advanced = await _hasAdvancedAlerts();
    final channelName = AppStrings.tCode(lang, 'notificationChannelName');
    final channelDesc = AppStrings.tCode(lang, 'notificationChannelDesc');

    final now = DateTime.now();
    var id = 1;

    for (final item in items) {
      if (item.expiryDate == null) continue;
      final expiry = item.expiryDate!;
      if (expiry.isBefore(now.subtract(const Duration(days: 1)))) continue;

      final alertDays = advanced ? [7, 3, 0] : [0];

      for (final daysBefore in alertDays) {
        final alertDate = DateTime(expiry.year, expiry.month, expiry.day).subtract(Duration(days: daysBefore));
        final alertTime = DateTime(alertDate.year, alertDate.month, alertDate.day, 9);
        if (alertTime.isBefore(now)) continue;

        final bodyKey = daysBefore == 0
            ? 'notificationExpiryBody'
            : daysBefore == 3
                ? 'notificationExpiry3Days'
                : 'notificationExpiry7Days';

        final body = AppStrings.tCode(lang, bodyKey, {
          'name': item.name,
          'days': '$daysBefore',
        });

        await _plugin.zonedSchedule(
          id++,
          'PantryPal',
          body,
          tz.TZDateTime.from(alertTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_channel',
              channelName,
              channelDescription: channelDesc,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }
}
