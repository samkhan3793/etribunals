import 'package:etribunals/core/utils/hearing_date.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HearingReminderService {
  HearingReminderService._();
  static final HearingReminderService instance = HearingReminderService._();

  static const testPayload = 'test';
  static const _testId = 900001;
  static const _channel = AndroidNotificationDetails(
    'hearings',
    'Hearing reminders',
    channelDescription: 'Reminders for followed tribunal cases',
    importance: Importance.high,
    priority: Priority.high,
  );

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final ValueNotifier<String?> tapPayload = ValueNotifier<String?>(null);
  bool _ready = false;

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onTap,
    );
    await requestPermission();
    _ready = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && payload != null && payload.isNotEmpty) {
      tapPayload.value = payload;
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    tapPayload.value = payload;
  }

  String? takePayload() {
    final value = tapPayload.value;
    tapPayload.value = null;
    return value;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<bool> osNotificationsOn() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<void> sendTest() async {
    if (!_ready) return;
    await requestPermission();
    await _plugin.show(
      _testId,
      'eTribunals reminder test',
      'Alerts are working. Tap to open My Cases.',
      const NotificationDetails(android: _channel),
      payload: testPayload,
    );
  }

  Future<void> rescheduleAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
    if (!await LocalStorageService.remindersEnabled()) return;
    final items = await LocalStorageService.getBookmarks();
    final now = tz.TZDateTime.now(tz.local);
    for (final item in items) {
      final date = parseHearingDate(item.nextHearing);
      if (date == null) continue;
      final caseNo = item.caseNo.trim().isNotEmpty ? item.caseNo.trim() : item.filingNo.trim();
      final parties = item.title.trim();
      final listing = DateFormat('dd-MM-yyyy').format(date);
      final morning = tz.TZDateTime(tz.local, date.year, date.month, date.day, 8);
      final eve = tz.TZDateTime(tz.local, date.year, date.month, date.day, 19).subtract(const Duration(days: 1));
      if (eve.isAfter(now)) {
        await _schedule(
          id: _id(item.id, evening: true),
          when: eve,
          title: 'Tomorrow • ${item.tribunal}',
          body: [if (caseNo.isNotEmpty) caseNo, 'listed $listing', if (parties.isNotEmpty) parties].join('  ·  '),
          payload: item.id,
        );
      }
      if (morning.isAfter(now)) {
        await _schedule(
          id: _id(item.id, evening: false),
          when: morning,
          title: 'Listed today • ${item.tribunal}',
          body: [if (caseNo.isNotEmpty) caseNo, if (parties.isNotEmpty) parties].join('  ·  '),
          payload: item.id,
        );
      }
    }
  }

  Future<BookmarkedCase?> caseForPayload(String payload) async {
    if (payload == testPayload) return null;
    final items = await LocalStorageService.getBookmarks();
    for (final item in items) {
      if (item.id == payload) return item;
    }
    return null;
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required String payload,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body.isEmpty ? 'Followed matter' : body,
      when,
      const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  int _id(String bookmarkId, {required bool evening}) {
    final base = bookmarkId.hashCode.abs() % 400000;
    return evening ? 100000 + base : 500000 + base;
  }
}
