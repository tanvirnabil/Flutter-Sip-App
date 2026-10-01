import 'dart:convert';

class SipAccount {
  final String extension;
  final String password;
  final String domain;
  final String displayName;
  final int port;
  final bool isWebRtc;
  final String transport;
  final String stunServer;

  const SipAccount({
    required this.extension,
    required this.password,
    required this.domain,
    this.displayName = '',
    this.port = 5060,
    this.isWebRtc = false,
    this.transport = 'udp',
    this.stunServer = 'stun:stun.l.google.com:19302',
  });

  String get sipUri => 'sip:$extension@$domain';

  String get resolvedWebSocketUrl {
    if (!isWebRtc) return '';
    final scheme = transport.toLowerCase() == 'ws' ? 'ws' : 'wss';
    return '$scheme://$domain:$port/ws';
  }

  String get formattedLabel => displayName.isNotEmpty ? '$displayName ($extension)' : extension;

  Map<String, dynamic> toMap() {
    return {
      'extension': extension,
      'password': password,
      'domain': domain,
      'displayName': displayName,
      'port': port,
      'isWebRtc': isWebRtc,
      'transport': transport,
      'stunServer': stunServer,
    };
  }

  factory SipAccount.fromMap(Map<String, dynamic> map) {
    return SipAccount(
      extension: map['extension'] ?? '',
      password: map['password'] ?? '',
      domain: map['domain'] ?? '',
      displayName: map['displayName'] ?? '',
      port: map['port'] is int ? map['port'] : int.tryParse(map['port']?.toString() ?? '5060') ?? 5060,
      isWebRtc: map['isWebRtc'] == true || map['isWebRtc'] == 1,
      transport: map['transport'] ?? 'udp',
      stunServer: map['stunServer'] ?? 'stun:stun.l.google.com:19302',
    );
  }

  String toJson() => json.encode(toMap());
  factory SipAccount.fromJson(String source) => SipAccount.fromMap(json.decode(source));
}

