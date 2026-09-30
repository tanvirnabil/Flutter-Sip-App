import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import '../models/sip_account.dart';
import '../models/call_session_model.dart';
import '../models/call_log_item.dart';
import '../services/sip_service.dart';
import '../services/call_history_service.dart';
import '../services/secure_storage_service.dart';

class SipProvider extends ChangeNotifier implements SipServiceListener {
  final SipService _sipService = SipService();
  final CallHistoryService _historyService = CallHistoryService();

  SipConnectionStatus _status = SipConnectionStatus.disconnected;
  String _statusMessage = 'Disconnected';
  SipAccount? _account;
  CallSessionModel? _session;

  Timer? _durationTimer;
  int _callDuration = 0;
  DateTime? _callStartTime;

  SipProvider() {
    _sipService.addListener(this);
    _initCallkitEventListener();
    _loadSavedAccount();
  }

  SipConnectionStatus get status => _status;
  String get statusMessage => _statusMessage;
  SipAccount? get account => _account;
  CallSessionModel? get session => _session;
  bool get isRegistered => _status == SipConnectionStatus.registered;
  bool get hasActiveCall => _session != null && _session!.status != AuraCallStatus.ended;
  int get callDuration => _callDuration;

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

  Future<bool> makeCall(String number) async {
    if (number.trim().isEmpty) return false;
    _callDuration = 0;
    _callStartTime = DateTime.now();
    final ok = await _sipService.makeCall(number);
    return ok;
  }

  void answerCall() {
    _sipService.answerCall();
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

  void toggleSpeaker() {
    _sipService.toggleSpeaker();
  }

  void sendDTMF(String tone) {
    _sipService.sendDTMF(tone);
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _callDuration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
  void onCallStateChanged(CallSessionModel session) {
    final previousStatus = _session?.status;
    _session = session;

    if (session.status == AuraCallStatus.active && previousStatus != AuraCallStatus.active) {
      _startTimer();
    } else if (session.status == AuraCallStatus.ended) {
      _stopTimer();
      _saveCallLog(session);
    }

    notifyListeners();
  }

  Future<void> _saveCallLog(CallSessionModel session) async {
    final type = session.direction == AuraCallDirection.outgoing
        ? CallLogType.outgoing
        : (_callDuration > 0 ? CallLogType.incoming : CallLogType.missed);

    final log = CallLogItem(
      phoneNumber: session.targetNumber,
      displayName: session.targetName,
      type: type,
      timestamp: _callStartTime ?? DateTime.now(),
      durationSeconds: _callDuration,
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
