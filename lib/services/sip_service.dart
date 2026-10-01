import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:sip_ua/sip_ua.dart';
import '../models/sip_account.dart';
import '../models/call_session_model.dart';
import 'audio_routing_service.dart';
import 'background_service.dart';
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

  final SIPUAHelper _helper = SIPUAHelper(
    customLogger: Logger(
      printer: SimplePrinter(printTime: false),
      level: Level.warning,
    ),
  );
  SipAccount? _currentAccount;
  Call? _activeCall;
  CallSessionModel? _currentSession;
  SipConnectionStatus _status = SipConnectionStatus.disconnected;
  String _statusMessage = 'Disconnected';

  final List<SipServiceListener> _listeners = [];
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isAutoReconnecting = false;
  bool _wasOffline = false;

  SipService._internal() {
    _helper.addSipUaHelperListener(this);
    _initConnectivityListener();
    _startKeepAliveLoop();
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

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (isOffline) {
        _wasOffline = true;
      } else if (_wasOffline) {
        _wasOffline = false;
        // Only reconnect if device was previously completely offline and is now back online
        if (_currentAccount != null && !_helper.registered) {
          _triggerAutoReconnect(immediate: true);
        }
      }
    });
  }

  void _startKeepAliveLoop() {
    _keepAliveTimer?.cancel();
    // Watchdog timer: checks every 30s if registration dropped unexpectedly
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentAccount != null &&
          !_helper.registered &&
          _status != SipConnectionStatus.connecting &&
          _status != SipConnectionStatus.registered) {
        _triggerAutoReconnect();
      }
    });
  }

  void _triggerAutoReconnect({bool immediate = false}) {
    if (_isAutoReconnecting || _currentAccount == null || _helper.registered) return;
    _isAutoReconnecting = true;
    _reconnectTimer?.cancel();

    final delay = immediate ? Duration.zero : const Duration(seconds: 8);
    _reconnectTimer = Timer(delay, () async {
      _isAutoReconnecting = false;
      if (_currentAccount != null && !_helper.registered) {
        _status = SipConnectionStatus.connecting;
        _statusMessage = 'Connecting to PBX...';
        _notifyRegistrationChanged();
        await register(_currentAccount!);
      }
    });
  }

  Future<void> register(SipAccount account) async {
    _currentAccount = account;
    _status = SipConnectionStatus.connecting;
    _statusMessage = 'Connecting to PBX (${account.isWebRtc ? "WebRTC" : "Standard SIP 5060"})...';
    _notifyRegistrationChanged();

    final settings = UaSettings();
    settings.uri = account.sipUri;
    settings.authorizationUser = account.extension;
    settings.password = account.password;
    settings.displayName = account.displayName.isNotEmpty ? account.displayName : account.extension;
    settings.iceServers = [
      {'urls': account.stunServer},
    ];

    if (account.isWebRtc) {
      // WebRTC mode (Asterisk WSS / FreePBX WebRTC)
      settings.transportType = TransportType.WS;
      final socketUrl = account.resolvedWebSocketUrl;
      settings.webSocketUrl = socketUrl.isNotEmpty ? socketUrl : 'ws://${account.domain}:${account.port}/ws';
      settings.webSocketSettings.allowBadCertificate = true;
    } else {
      // Standard SIP mode (UDP/TCP Port 5060)
      settings.transportType = TransportType.TCP;
      settings.host = account.domain;
      settings.port = account.port.toString();
      settings.tcpSocketSettings.allowBadCertificate = true;
    }

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
      _reconnectTimer?.cancel();
      _isAutoReconnecting = false;
      await _helper.unregister(true);
      _helper.stop();
      _status = SipConnectionStatus.disconnected;
      _statusMessage = 'Disconnected';
      _currentAccount = null;
      await BackgroundService().stopService();
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
        BackgroundService().startService(accountExtension: _currentAccount?.extension);
        BackgroundService().updateStatus('Ext ${_currentAccount?.extension ?? ""} • Registered');
        break;
      case RegistrationStateEnum.UNREGISTERED:
        _status = SipConnectionStatus.disconnected;
        _statusMessage = 'Disconnected';
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        _status = SipConnectionStatus.registrationFailed;
        final causeStr = state.cause?.toString().toLowerCase() ?? '';
        if (causeStr.contains('403') || causeStr.contains('forbidden')) {
          _statusMessage = 'Authentication Failed (403): Check extension password.';
        } else if (causeStr.contains('404') || causeStr.contains('not found')) {
          _statusMessage = 'Extension Not Found (404): Check extension number.';
        } else if (causeStr.contains('408') || causeStr.contains('timeout')) {
          _statusMessage = 'PBX Timeout (408): sip.ranksitt.net unreachable.';
        } else if (causeStr.contains('503') || causeStr.contains('service unavailable')) {
          _statusMessage = 'PBX Unavailable (503): PBX temporarily down.';
        } else {
          _statusMessage = 'Registration failed';
        }
        // Automatically retry with backoff if not a permanent auth error
        if (_currentAccount != null && !causeStr.contains('403')) {
          _triggerAutoReconnect();
        }
        break;
      case RegistrationStateEnum.NONE:
      default:
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
      // Only announce transport connected if not already in fully registered state
      if (_status != SipConnectionStatus.registered) {
        _status = SipConnectionStatus.connected;
        _statusMessage = 'PBX Transport Connected';
        _notifyRegistrationChanged();
      }
    } else if (state.state == TransportStateEnum.DISCONNECTED) {
      // Allow sip_ua internal socket recovery to reconnect without thrashing registered UI status
      if (_status == SipConnectionStatus.connecting) {
        _statusMessage = 'Connecting to PBX...';
        _notifyRegistrationChanged();
      }
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

  void dispose() {
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectivitySubscription?.cancel();
  }
}
