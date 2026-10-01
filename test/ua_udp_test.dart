import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:sip_ua/src/config.dart';
import 'package:sip_ua/src/event_manager/register_events.dart';
import 'package:sip_ua/src/logger.dart' as sip_log;
import 'package:sip_ua/src/transports/socket_interface.dart';
import 'package:sip_ua/src/ua.dart';
import 'package:sip_ua/src/utils.dart' as utils;

class SIPUAUdpSocket extends SIPUASocketInterface {
  final String _host;
  final String _port;
  int? _weight;
  late String _viaTransport;
  String? _sipUri;

  RawDatagramSocket? _socket;
  InternetAddress? _remoteAddress;
  bool _connected = false;
  bool _connecting = false;
  StreamSubscription? _sub;

  SIPUAUdpSocket(this._host, this._port, {int? weight}) {
    _weight = weight;
    _viaTransport = 'UDP';
    _sipUri = 'sip:$_host:$_port;transport=udp';
  }

  @override
  String get via_transport => _viaTransport;

  @override
  set via_transport(String value) {
    _viaTransport = value.toUpperCase();
  }

  @override
  int? get weight => _weight;

  @override
  String? get sip_uri => _sipUri;

  @override
  String? get url => '$_host:$_port';

  @override
  bool isConnected() => _connected;

  @override
  bool isConnecting() => _connecting;

  @override
  void connect() async {
    if (_connected) return;
    _connecting = true;

    try {
      final addresses = await InternetAddress.lookup(_host);
      _remoteAddress = addresses.first;
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      _sub = _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket!.receive();
          if (dg != null && dg.data.isNotEmpty) {
            final message = utf8.decode(dg.data, allowMalformed: true);
            if (message.trim().isNotEmpty) {
              ondata?.call(message);
            }
          }
        }
      }, onError: (err) {
        _connected = false;
        _connecting = false;
        ondisconnect?.call(this, true, 500, err.toString());
      }, onDone: () {
        _connected = false;
        _connecting = false;
        ondisconnect?.call(this, false, 0, 'Socket closed');
      });

      _connecting = false;
      _connected = true;
      onconnect?.call();
    } catch (e) {
      _connecting = false;
      _connected = false;
      ondisconnect?.call(this, true, 500, e.toString());
    }
  }

  @override
  bool send(dynamic message) {
    if (_socket == null || _remoteAddress == null) return false;
    try {
      final bytes = message is String ? utf8.encode(message) : (message as List<int>);
      final targetPort = int.tryParse(_port) ?? 5060;
      _socket!.send(bytes, _remoteAddress!, targetPort);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void disconnect() {
    _connected = false;
    _connecting = false;
    _sub?.cancel();
    _socket?.close();
    _socket = null;
    ondisconnect?.call(this, false, 0, 'Client disconnected');
  }
}

void main() {
  test('Test UA with SIPUAUdpSocket against sip.ranksitt.net:5060', () async {
    sip_log.logger = Logger(printer: SimplePrinter(printTime: false));
    print('Starting UA UDP test against sip.ranksitt.net:5060...');
    final udpSocket = SIPUAUdpSocket('sip.ranksitt.net', '5060');

    final settings = Settings();
    settings.sockets = [udpSocket];
    settings.transportType = TransportType.WS; // allows socket.via_transport to take effect
    settings.uri = utils.normalizeTarget('sip:09617733133@sip.ranksitt.net');
    settings.authorization_user = '09617733133';
    settings.password = 'au9g9qiue2';
    settings.display_name = '09617733133';
    settings.register = true;

    final completer = Completer<bool>();

    final ua = UA(settings);

    ua.on(EventRegistered(), (EventRegistered e) {
      print('>>> UDP REGISTERED SUCCESSFULLY! Cause: ${e.cause}');
      if (!completer.isCompleted) completer.complete(true);
    });

    ua.on(EventRegistrationFailed(), (EventRegistrationFailed e) {
      print('>>> UDP REGISTRATION FAILED! Cause: ${e.cause}');
      if (!completer.isCompleted) completer.complete(false);
    });

    ua.start();

    final result = await completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      print('UDP Registration timed out');
      return false;
    });

    ua.stop();
    expect(result, isTrue);
  });
}
