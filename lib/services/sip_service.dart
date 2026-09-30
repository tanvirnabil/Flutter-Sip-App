import 'dart:async';
import 'package:sip_ua/sip_ua.dart';
import '../models/sip_account.dart';
import '../models/call_session_model.dart';
import 'audio_routing_service.dart';
import 'callkit_service.dart';

enum SipConnectionStatus {
  disconnected,
  connecting,
  connected,
  registered,
  registrationFailed,
}

abstract class SipServiceListener {
  void onRegistrationStateChanged(SipConnectionStatus status, String message);
  void onCallStateChanged(CallSessionModel session);
}

class SipService implements SipUaHelperListener {
  static final SipService _instance = SipService._internal();
  factory SipService() => _instance;

  final SIPUAHelper _helper = SIPUAHelper();
  SipAccount? _currentAccount;
  Call? _activeCall;
  CallSessionModel? _currentSession;
  SipConnectionStatus _status = SipConnectionStatus.disconnected;
  String _statusMessage = 'Disconnected';

  final List<SipServiceListener> _listeners = [];

  SipService._internal() {
    _helper.addSipUaHelperListener(this);
  }

  SipConnectionStatus get status => _status;
  String get statusMessage => _statusMessage;
  SipAccount? get currentAccount => _currentAccount;
  Call? get activeCall => _activeCall;
  CallSessionModel? get currentSession => _currentSession;
  SIPUAHelper get helper => _helper;

  void addListener(SipServiceListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(SipServiceListener listener) {
    _listeners.remove(listener);
  }

  Future<void> register(SipAccount account) async {
    _currentAccount = account;
    _status = SipConnectionStatus.connecting;
    _statusMessage = 'Connecting to PBX...';
    _notifyRegistrationChanged();

    final settings = UaSettings();
    final socketUrl = account.resolvedWebSocketUrl;

    settings.webSocketUrl = socketUrl.isNotEmpty ? socketUrl : 'ws://${account.domain}:${account.port}/ws';
    settings.webSocketSettings.allowBadCertificate = true;
    settings.uri = account.sipUri;
    settings.authorizationUser = account.extension;
    settings.password = account.password;
    settings.displayName = account.displayName.isNotEmpty ? account.displayName : account.extension;
    settings.transportType = TransportType.WS;
    settings.iceServers = [
      {'urls': account.stunServer},
    ];

    try {
      _helper.start(settings);
    } catch (e) {
      _status = SipConnectionStatus.registrationFailed;
      _statusMessage = 'Connection error: ${e.toString()}';
      _notifyRegistrationChanged();
    }
  }

  Future<void> unregister() async {
    try {
      await _helper.unregister(true);
      _helper.stop();
      _status = SipConnectionStatus.disconnected;
      _statusMessage = 'Disconnected';
      _currentAccount = null;
      _notifyRegistrationChanged();
    } catch (_) {}
  }

  Future<bool> makeCall(String destination) async {
    if (_currentAccount == null) return false;
    final cleanDest = destination.trim();
    if (cleanDest.isEmpty) return false;

    final target = 'sip:$cleanDest@${_currentAccount!.domain}';

    _currentSession = CallSessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      targetNumber: cleanDest,
      direction: AuraCallDirection.outgoing,
      status: AuraCallStatus.connecting,
    );
    _notifyCallStateChanged();

    try {
      final success = await _helper.call(
        target,
        voiceOnly: true,
      );
      return success;
    } catch (e) {
      _currentSession = _currentSession?.copyWith(status: AuraCallStatus.ended);
      _notifyCallStateChanged();
      return false;
    }
  }

  void answerCall() {
    if (_activeCall != null) {
      _activeCall!.answer(_helper.buildCallOptions(true));
      _currentSession = _currentSession?.copyWith(status: AuraCallStatus.active);
      _notifyCallStateChanged();
    }
  }

  void hangup() {
    if (_activeCall != null) {
      _activeCall!.hangup();
    }
    CallKitService.endAllCalls();
    _currentSession = _currentSession?.copyWith(status: AuraCallStatus.ended);
    _notifyCallStateChanged();
    _activeCall = null;
    _currentSession = null;
  }

  void toggleMute() {
    if (_activeCall != null && _currentSession != null) {
      final newMuteState = !_currentSession!.isMuted;
      _activeCall!.mute(newMuteState, false);
      _currentSession = _currentSession!.copyWith(isMuted: newMuteState);
      _notifyCallStateChanged();
    }
  }

  void toggleHold() {
    if (_activeCall != null && _currentSession != null) {
      final newHoldState = !_currentSession!.isOnHold;
      if (newHoldState) {
        _activeCall!.hold();
        _currentSession = _currentSession!.copyWith(isOnHold: true, status: AuraCallStatus.held);
      } else {
        _activeCall!.unhold();
        _currentSession = _currentSession!.copyWith(isOnHold: false, status: AuraCallStatus.active);
      }
      _notifyCallStateChanged();
    }
  }

  Future<void> toggleSpeaker() async {
    await AudioRoutingService.toggleSpeaker();
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(isSpeaker: AudioRoutingService.isSpeakerOn);
      _notifyCallStateChanged();
    }
  }

  void sendDTMF(String tone) {
    if (_activeCall != null) {
      _activeCall!.sendDTMF(tone);
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        _status = SipConnectionStatus.registered;
        _statusMessage = 'Connected & Registered';
        break;
      case RegistrationStateEnum.UNREGISTERED:
        _status = SipConnectionStatus.disconnected;
        _statusMessage = 'Unregistered';
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        _status = SipConnectionStatus.registrationFailed;
        _statusMessage = state.cause?.toString() ?? 'Registration failed';
        break;
      case RegistrationStateEnum.NONE:
      default:
        _status = SipConnectionStatus.disconnected;
        _statusMessage = 'Idle';
        break;
    }
    _notifyRegistrationChanged();
  }

  @override
  void callStateChanged(Call call, CallState state) {
    _activeCall = call;

    final remoteNumber = call.remote_identity ?? 'Unknown';
    final remoteName = call.remote_display_name ?? '';
    final isIncoming = call.direction.toString().toUpperCase().contains('INCOMING');

    switch (state.state) {
      case CallStateEnum.CALL_INITIATION:
        _currentSession = CallSessionModel(
          id: call.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          targetNumber: remoteNumber,
          targetName: remoteName,
          direction: isIncoming ? AuraCallDirection.incoming : AuraCallDirection.outgoing,
          status: AuraCallStatus.connecting,
        );
        if (isIncoming) {
          CallKitService.showIncomingCall(
            uuid: _currentSession!.id,
            callerName: remoteName,
            callerNumber: remoteNumber,
          );
        }
        break;

      case CallStateEnum.PROGRESS:
      case CallStateEnum.CONNECTING:
        _currentSession = _currentSession?.copyWith(status: AuraCallStatus.ringing) ??
            CallSessionModel(
              id: call.id ?? '',
              targetNumber: remoteNumber,
              targetName: remoteName,
              direction: isIncoming ? AuraCallDirection.incoming : AuraCallDirection.outgoing,
              status: AuraCallStatus.ringing,
            );
        break;

      case CallStateEnum.CONFIRMED:
      case CallStateEnum.ACCEPTED:
        _currentSession = _currentSession?.copyWith(
              status: AuraCallStatus.active,
              startedAt: DateTime.now(),
            ) ??
            CallSessionModel(
              id: call.id ?? '',
              targetNumber: remoteNumber,
              targetName: remoteName,
              direction: isIncoming ? AuraCallDirection.incoming : AuraCallDirection.outgoing,
              status: AuraCallStatus.active,
              startedAt: DateTime.now(),
            );
        break;

      case CallStateEnum.HOLD:
        _currentSession = _currentSession?.copyWith(status: AuraCallStatus.held, isOnHold: true);
        break;

      case CallStateEnum.UNHOLD:
        _currentSession = _currentSession?.copyWith(status: AuraCallStatus.active, isOnHold: false);
        break;

      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _currentSession = _currentSession?.copyWith(status: AuraCallStatus.ended);
        CallKitService.endAllCalls();
        _notifyCallStateChanged();
        _activeCall = null;
        _currentSession = null;
        return;

      default:
        break;
    }

    if (_currentSession != null) {
      _notifyCallStateChanged();
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    if (state.state == TransportStateEnum.CONNECTED) {
      _status = SipConnectionStatus.connected;
      _statusMessage = 'WebSocket Connected';
      _notifyRegistrationChanged();
    } else if (state.state == TransportStateEnum.DISCONNECTED) {
      _status = SipConnectionStatus.disconnected;
      _statusMessage = 'Transport Disconnected';
      _notifyRegistrationChanged();
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  void _notifyRegistrationChanged() {
    for (final l in List<SipServiceListener>.from(_listeners)) {
      l.onRegistrationStateChanged(_status, _statusMessage);
    }
  }

  void _notifyCallStateChanged() {
    if (_currentSession != null) {
      for (final l in List<SipServiceListener>.from(_listeners)) {
        l.onCallStateChanged(_currentSession!);
      }
    }
  }
}
