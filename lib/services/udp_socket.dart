import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sip_ua/src/transports/socket_interface.dart';

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
      if (addresses.isEmpty) {
        throw Exception('Cannot resolve host $_host');
      }
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
        ondisconnect?.call(this, false, 0, 'UDP Socket closed');
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
    if (_socket == null || _remoteAddress == null) {
      return false;
    }
    try {
      final List<int> bytes = message is String ? utf8.encode(message) : (message as List<int>);
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
    ondisconnect?.call(this, false, 0, 'Client disconnect');
  }
}

