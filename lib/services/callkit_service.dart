import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'background_service.dart';
import 'ringtone_service.dart';

class CallKitService {
  static Future<void> showIncomingCall({
    required String uuid,
    required String callerName,
    required String callerNumber,
  }) async {
    // 1. Wake the screen immediately even if phone is sleeping
    BackgroundService.wakeScreen();

    final selectedRingtone = RingtoneService().selectedRingtoneId;
    final ringtonePath = selectedRingtone == 'system_default'
        ? 'system_ringtone_default'
        : selectedRingtone;

    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName.isNotEmpty ? callerName : callerNumber,
      appName: 'Aura VoIP',
      avatar: '',
      handle: callerNumber,
      type: 0,
      duration: 35000,
      extra: <String, dynamic>{'callerNumber': callerNumber},
      headers: <String, dynamic>{'platform': 'flutter'},
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: ringtonePath,
        backgroundColor: '#0F172A',
        actionColor: '#22C55E',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: 'Aura VoIP Incoming Call',
        missedCallNotificationChannelName: 'Aura VoIP Missed Call',
        isShowCallID: true,
        isShowFullLockedScreen: true,
      ),
      ios: IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: ringtonePath,
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (_) {}
  }

  static Future<void> endCall(String uuid) async {
    try {
      await FlutterCallkitIncoming.endCall(uuid);
    } catch (_) {}
  }

  static Future<void> endAllCalls() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }
}
