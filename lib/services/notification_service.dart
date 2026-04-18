
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
static final FlutterLocalNotificationsPlugin _plugin =
FlutterLocalNotificationsPlugin();

static bool _initialized = false;

// ── Initialize ─────────────────────────────────────────────────────────────
static Future<void> init() async {
if (_initialized) return;

tz.initializeTimeZones();

const android = AndroidInitializationSettings('@mipmap/ic_launcher');

const ios = DarwinInitializationSettings(
requestAlertPermission: true,
requestBadgePermission: true,
requestSoundPermission: true,
);

const settings = InitializationSettings(
android: android,
iOS: ios,
);

await _plugin.initialize(
  settings: settings,
  onDidReceiveNotificationResponse: _onTap,
);

// Android 13+ permission
await _plugin
    .resolvePlatformSpecificImplementation<
AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();

_initialized = true;
}

static void _onTap(NotificationResponse response) {
debugPrint('Notification tapped: ${response.payload}');
}

// ── Notification Details ───────────────────────────────────────────────────
static const NotificationDetails _details = NotificationDetails(
android: AndroidNotificationDetails(
'speakup_channel',
'SpeakUp Reminders',
channelDescription: 'Daily practice reminders',
importance: Importance.high,
priority: Priority.high,
icon: '@mipmap/ic_launcher',
color: Color(0xFF00C896),
enableLights: true,
enableVibration: true,
playSound: true,
styleInformation: BigTextStyleInformation(''),
),
iOS: DarwinNotificationDetails(
presentAlert: true,
presentBadge: true,
presentSound: true,
),
);

// ── Daily Reminder ─────────────────────────────────────────────────────────
static Future<void> scheduleDailyReminder({
required int hour,
required int minute,
required String userName,
bool skipToday = false,
}) async {
await cancelDailyReminder();

final messages = [
'🎤 Time to practice, $userName! Your speaking skills are waiting.',
'💼 Ready for your mock interview today, $userName?',
'🏆 Keep your streak alive! Practice English for just 10 minutes.',
'🚀 $userName, one practice session = one step closer to your dream job!',
'📈 Your consistency is your superpower. Let\'s practice today!',
];

final msg = messages[DateTime.now().weekday % messages.length];

await _plugin.zonedSchedule(
id: 0,
title: '⏰ SpeakUp Reminder',
body: msg,
scheduledDate: _nextInstanceOfTime(hour, minute, skipToday),
notificationDetails: _details,
androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
matchDateTimeComponents: DateTimeComponents.time,
payload: 'daily_reminder',
);

debugPrint('✅ Daily reminder set at $hour:$minute (skipToday: $skipToday)');
}

// ── Cancel Reminders ───────────────────────────────────────────────────────
static Future<void> cancelDailyReminder() async {
await _plugin.cancel(id: 0);
}

static Future<void> cancelTestReminder() async {
await _plugin.cancel(id: 10);
}

static Future<void> cancelAll() async {
await _plugin.cancelAll();
}

// ── Weekly Test Reminder ──────────────────────────────────────────────────
static Future<void> scheduleWeeklyTestReminder({
required int hour,
required int minute,
}) async {
await cancelTestReminder();

await _plugin.zonedSchedule(
id: 10,
title: '📝 Sunday Test Reminder',
body: 'It\'s Sunday! Time to test your progress and reach new heights. 🚀',
scheduledDate: _nextInstanceOfWeekday(DateTime.sunday, hour, minute),
notificationDetails: _details,
androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
payload: 'test_reminder',
);

debugPrint('✅ Weekly Test reminder set for Sunday at $hour:$minute');
}

// ── Instant Notification ───────────────────────────────────────────────────
static Future<void> sendInstant({
required String title,
required String body,
}) async {
await _plugin.show(
id: 99,
title: title,
body: body,
notificationDetails: _details,
payload: 'instant',
);
}

// ── Streak Notification ────────────────────────────────────────────────────
static Future<void> sendStreakReminder(int streakDays) async {
await _plugin.show(
id: 1,
title: '🔥 Don\'t break your streak!',
body:
'You\'re on a $streakDays-day streak. Practice today to keep it alive!',
notificationDetails: _details,
payload: 'streak',
);
}

// ── Achievement Notification ───────────────────────────────────────────────
static Future<void> sendAchievement(
String badge, String message) async {
await _plugin.show(
id: 2,
title: '🏅 Achievement Unlocked: $badge',
body: message,
notificationDetails: _details,
payload: 'achievement',
);
}

// ── XP Milestone ──────────────────────────────────────────────────────────
static Future<void> sendXPMilestone(int xp) async {
await _plugin.show(
id: 3,
title: '⭐ XP Milestone Reached!',
body:
'Wow! You\'ve earned $xp XP. Keep going, you\'re on fire! 🔥',
notificationDetails: _details,
payload: 'xp_milestone',
);
}

// ── Pending Notifications ──────────────────────────────────────────────────
static Future<List<PendingNotificationRequest>> getPending() async {
return await _plugin.pendingNotificationRequests();
}

static tz.TZDateTime _nextInstanceOfWeekday(int day, int hour, int minute) {
tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
while (scheduledDate.weekday != day) {
scheduledDate = scheduledDate.add(const Duration(days: 1));
}
return scheduledDate;
}

static tz.TZDateTime _nextInstanceOfTime(int hour, int minute, [bool skipToday = false]) {
final now = tz.TZDateTime.now(tz.local);

var scheduled =
tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

if (skipToday || scheduled.isBefore(now)) {
scheduled = scheduled.add(const Duration(days: 1));
}

return scheduled;
}
}

