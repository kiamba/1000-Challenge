import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationEngine {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  // This function scans Firestore locally from the user's phone on login/app open!
  Future<void> checkAndTriggerAlerts(String currentUserId) async {
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 2));

    // Pull down records strictly belonging to the active device user
    final snapshot = await FirebaseFirestore.instance
        .collection('tracked_actions')
        .where('userId', isEqualTo: currentUserId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['followUpDate'] == null) continue;

      DateTime recordDate;
      if (data['followUpDate'] is String) {
        recordDate = DateTime.parse(data['followUpDate']);
      } else {
        recordDate = (data['followUpDate'] as Timestamp).toDate();
      }

      // If a record matches exactly 48 hours out, trigger a system notification drawer alert instantly!
      if (recordDate.year == targetDate.year &&
          recordDate.month == targetDate.month &&
          recordDate.day == targetDate.day) {
        
        await _notificationsPlugin.show(
          doc.id.hashCode,
          "⏰ 1000 Challenge Reminder",
          "Your follow-up for '${data['roleOpportunity']}' is due in 2 days!",
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'challenge_channel_id',
              'Challenge Alerts',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  }
}