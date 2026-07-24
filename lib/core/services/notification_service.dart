import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

const String stopActionId = 'stop_action';
const String snoozeActionId = 'snooze_action';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
    // ignore: avoid_print
    print(
      '[NotificationService] Saat dilimi ayarlandi: ${currentTimeZone.identifier}',
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    final initialized = await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    // ignore: avoid_print
    print('[NotificationService] Plugin baslatildi mi: $initialized');

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _plugin.resolvePlatformSpecificImplementation();
    // ignore: avoid_print
    print(
      '[NotificationService] Android implementation null mu: ${androidImplementation == null}',
    );

    final notifPermission = await androidImplementation
        ?.requestNotificationsPermission();
    // ignore: avoid_print
    print('[NotificationService] Bildirim izni sonucu: $notifPermission');

    final alarmPermission = await androidImplementation
        ?.requestExactAlarmsPermission();
    // ignore: avoid_print
    print('[NotificationService] Exact alarm izni sonucu: $alarmPermission');
  }

  void _onNotificationResponse(NotificationResponse response) {
    // ignore: avoid_print
    print(
      '[NotificationService] Bildirim yaniti alindi. actionId=${response.actionId}, id=${response.id}',
    );

    if (response.actionId == stopActionId) {
      // ignore: avoid_print
      print('[NotificationService] DURDUR basildi, bildirim iptal ediliyor.');
      if (response.id != null) {
        _plugin.cancel(response.id!);
      }
    } else if (response.actionId == snoozeActionId) {
      // ignore: avoid_print
      print(
        '[NotificationService] ERTELE basildi, 5 dakika sonraya yeniden planlaniyor.',
      );
      if (response.id != null) {
        final newTime = DateTime.now().add(const Duration(minutes: 5));
        scheduleTaskNotification(
          id: response.id!,
          title: response.payload ?? 'Görev hatırlatması',
          body: 'Ertelenen görev zamanı geldi',
          scheduledDate: newTime,
        );
      }
    }
  }

  Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // ignore: avoid_print
    print(
      '[NotificationService] scheduleTaskNotification CAGRILDI. id=$id, scheduledDate=$scheduledDate, now=${DateTime.now()}',
    );

    if (scheduledDate.isBefore(DateTime.now())) {
      // ignore: avoid_print
      print(
        '[NotificationService] UYARI: scheduledDate gecmiste, planlama IPTAL edildi.',
      );
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Gorev Hatirlatmalari',
      channelDescription: 'Gorevlerin son tarihinde gelen bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      actions: const [
        AndroidNotificationAction(
          stopActionId,
          'Durdur',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          snoozeActionId,
          'Ertele',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    // ignore: avoid_print
    print(
      '[NotificationService] Planlanan TZDateTime: $tzDate (tz.local: ${tz.local.name})',
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: title,
      );
      // ignore: avoid_print
      print('[NotificationService] zonedSchedule BASARIYLA cagrildi, id=$id');
    } catch (e, stack) {
      // ignore: avoid_print
      print('[NotificationService] HATA: zonedSchedule basarisiz: $e');
      // ignore: avoid_print
      print('$stack');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_alerts',
      'Sayac Bildirimleri',
      channelDescription: 'Sayac/zamanlayici tamamlandiginda gelen bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(id, title, body, notificationDetails);
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationService] HATA: showInstantNotification basarisiz: $e');
    }
  }
}