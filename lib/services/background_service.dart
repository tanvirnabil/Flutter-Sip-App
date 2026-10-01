import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;

  bool _isServiceRunning = false;
  bool _isIgnoringBattery = false;

  BackgroundService._internal();

  bool get isServiceRunning => _isServiceRunning;
  bool get isIgnoringBattery => _isIgnoringBattery;

  /// Initializes the foreground task configuration
  Future<void> init() async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'aura_voip_background',
          channelName: 'Aura VoIP Background Service',
          channelDescription: 'Maintains 24/7 SIP connection for incoming calls',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(30000),
          autoRunOnBoot: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      _isIgnoringBattery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      _isServiceRunning = await FlutterForegroundTask.isRunningService;
    } catch (e) {
      debugPrint('BackgroundService init error: $e');
    }
  }

  /// Starts the persistent foreground task so the SIP socket stays alive in background
  Future<void> startService({String? accountExtension}) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        _isServiceRunning = true;
        return;
      }

      final ext = accountExtension != null && accountExtension.isNotEmpty ? 'Ext $accountExtension' : 'SIP';
      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.phoneCall],
        notificationTitle: 'Aura VoIP',
        notificationText: '$ext • Ready for incoming calls',
      );
      _isServiceRunning = true;
    } catch (e) {
      debugPrint('Error starting BackgroundService: $e');
    }
  }

  /// Updates status notification text (e.g. Registered / Reconnecting)
  Future<void> updateStatus(String statusText) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Aura VoIP',
          notificationText: statusText,
        );
      }
    } catch (_) {}
  }

  /// Stops the background service (e.g. on manual logout)
  Future<void> stopService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
      _isServiceRunning = false;
    } catch (e) {
      debugPrint('Error stopping BackgroundService: $e');
    }
  }

  /// Checks if battery optimization is ignored
  Future<bool> checkBatteryOptimization() async {
    try {
      _isIgnoringBattery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      return _isIgnoringBattery;
    } catch (_) {
      return false;
    }
  }

  /// Requests exemption from Android battery optimization to prevent OS from killing socket
  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final success = await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      _isIgnoringBattery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      return success;
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  /// Turns on device screen when incoming call arrives
  static void wakeScreen() {
    try {
      FlutterForegroundTask.wakeUpScreen();
    } catch (_) {}
  }

  /// Brings the app to the foreground on call accept
  static void launchApp() {
    try {
      FlutterForegroundTask.launchApp();
    } catch (_) {}
  }
}

