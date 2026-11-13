/// Ongoing progress notification for transcription. Shown while a job runs,
/// updated as percent advances, cancelled or replaced at the end.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const _channelId = 'kikoe_transcribe';
  static const _channelName = 'Transcription progress';
  static const _notificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  void Function()? onCancelRequested;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'cancel') {
          onCancelRequested?.call();
        }
      },
    );
    await requestPermission();
  }

  Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  AndroidNotificationDetails _progressDetails(int percent, {bool ongoing = true}) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Progress of the current transcription',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: ongoing,
      autoCancel: false,
      onlyAlertOnce: true,
      showProgress: ongoing,
      progress: percent,
      maxProgress: 100,
      actions: const [
        AndroidNotificationAction('cancel', 'Cancel', cancelNotification: true),
      ],
    );
  }

  Future<void> showProgress(int percent) async {
    final clamped = percent.clamp(0, 100);
    try {
      await _plugin.show(
        _notificationId,
        'Kikoe',
        'Transcribing… $clamped%',
        NotificationDetails(android: _progressDetails(clamped)),
        payload: 'run',
      );
    } catch (_) {
      // Notifications are best-effort; transcription must not fail over them.
    }
  }

  Future<void> showDone(String fileName) async {
    const details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    try {
      await _plugin.show(
        _notificationId + 1,
        'Kikoe',
        'Finished transcribing $fileName',
        const NotificationDetails(android: details),
      );
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      await _plugin.cancel(_notificationId);
    } catch (_) {}
  }
}
