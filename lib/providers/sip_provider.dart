import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/sip_account.dart';
import '../models/call_session_model.dart';
import '../models/call_log_item.dart';
import '../services/sip_service.dart';
import '../services/call_history_service.dart';
import '../services/call_recording_service.dart';
import '../services/secure_storage_service.dart';
import '../services/background_service.dart';

class SipProvider extends ChangeNotifier implements SipServiceListener {
  final SipService _sipService = SipService();
  final CallHistoryService _historyService = CallHistoryService();

  SipConnectionStatus _status = SipConnectionStatus.disconnected;
  String _statusMessage = 'Disconnected';
  SipAccount? _account;
  CallSessionModel? _session;
  int _callDuration = 0;
  Timer? _durationTimer;
  DateTime? _callStartTime;

  SipProvider() {
    _sipService.addListener(this);
    _loadSavedAccount();
    _initCallkitEventListener();
  }

  SipConnectionStatus get status => _status;
  String get statusMessage => _statusMessage;
  SipAccount? get account => _account;
  CallSessionModel? get session => _session;
  bool get isRegistered => _status == SipConnectionStatus.registered;
  bool get hasActiveCall => _session != null && _session!.status != AuraCallStatus.ended;
  int get callDuration => _callDuration;

  RTCVideoRenderer get localRenderer => _sipService.localRenderer;
  RTCVideoRenderer get remoteRenderer => _sipService.remoteRenderer;

  String get formattedDuration {
    final minutes = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _loadSavedAccount() async {
    final saved = await SecureStorageService.getAccount();
    if (saved != null) {
      _account = saved;
      notifyListeners();
      register(saved);
    }
  }

  void _initCallkitEventListener() {
    try {
      FlutterCallkitIncoming.onEvent.listen((event) {
        if (event == null) return;
        final name = event.eventName.toUpperCase();
        if (name.contains('ACCEPT')) {
          answerCall();
          BackgroundService.launchApp();
        } else if (name.contains('DECLINE') || name.contains('ENDED')) {
          hangup();
        }
      });
    } catch (_) {}
  }

  Future<void> register(SipAccount account) async {
    _account = account;
    await SecureStorageService.saveAccount(account);
    notifyListeners();
    await _sipService.register(account);
  }

  Future<void> unregister() async {
    await _sipService.unregister();
    await SecureStorageService.clearAccount();
    _account = null;
    notifyListeners();
  }

  Future<bool> makeCall(String number, {bool isVideo = false}) async {
    if (number.trim().isEmpty) return false;
    _callDuration = 0;
    _callStartTime = DateTime.now();
    final ok = await _sipService.makeCall(number, isVideo: isVideo);
    return ok;
  }

  void answerCall({bool isVideo = false}) {
    _sipService.answerCall(isVideo: isVideo);
  }

  void hangup() {
    _sipService.hangup();
    _stopTimer();
  }

  void toggleMute() {
    _sipService.toggleMute();
  }

  void toggleHold() {
    _sipService.toggleHold();
  }

  Future<void> toggleSpeaker() async {
    await _sipService.toggleSpeaker();
  }

  void sendDTMF(String tone) {
    _sipService.sendDTMF(tone);
  }

  bool sendTextMessage(String target, String body) {
    return _sipService.sendTextMessage(target, body);
  }

  Future<void> switchCamera() async {
    await _sipService.switchCamera();
  }

  void toggleCamera() {
    _sipService.toggleCamera();
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _callDuration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration++;
      if (_session != null) {
        _session = _session!.copyWith(durationSeconds: _callDuration);
      }
      notifyListeners();
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  @override
  void onRegistrationStateChanged(SipConnectionStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void onCallStateChanged(CallSessionModel session) async {
    final previousStatus = _session?.status;
    _session = session;

    if (_callStartTime == null &&
        (session.status == AuraCallStatus.connecting ||
            session.status == AuraCallStatus.ringing ||
            session.status == AuraCallStatus.active)) {
      _callStartTime = session.startedAt ?? DateTime.now();
    }

    if (session.status == AuraCallStatus.active && previousStatus != AuraCallStatus.active) {
      _startTimer();
      // Auto-start recording if enabled in settings
      if (CallRecordingService().isAutoRecordEnabled) {
        await CallRecordingService().startRecording(session.id, session.targetNumber);
      }
    } else if (session.status == AuraCallStatus.ended) {
      _stopTimer();
      final recordingPath = await CallRecordingService().stopRecording();
      await _saveCallLog(session, recordingPath: recordingPath);
      _callStartTime = null;
      _callDuration = 0;
    }

    notifyListeners();
  }

  Future<void> _saveCallLog(CallSessionModel session, {String? recordingPath}) async {
    final type = session.direction == AuraCallDirection.outgoing
        ? CallLogType.outgoing
        : (_callDuration > 0 ? CallLogType.incoming : CallLogType.missed);

    final rawTarget = session.targetNumber.trim();
    final target = rawTarget.isNotEmpty ? rawTarget : 'Unknown';
    final name = session.targetName.isNotEmpty ? session.targetName : target;

    final log = CallLogItem(
      phoneNumber: target,
      displayName: name,
      type: type,
      timestamp: _callStartTime ?? DateTime.now(),
      durationSeconds: _callDuration,
      recordingPath: recordingPath,
    );

    await _historyService.insertCallLog(log);
  }

  @override
  void dispose() {
    _stopTimer();
    _sipService.removeListener(this);
    super.dispose();
  }
}
