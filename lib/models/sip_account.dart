import 'dart:convert';

class SipAccount {
  final String _id;
  final String _accountName;
  final String extension;
  final String password;
  final String domain;
  final String displayName;
  final int port;
  final bool isWebRtc;
  final String transport;
  final String stunServer;

  // ignore: prefer_initializing_formals
  const SipAccount({
    String id = '',
    String accountName = '',
    required this.extension,
    required this.password,
    required this.domain,
    this.displayName = '',
    this.port = 5060,
    this.isWebRtc = false,
    this.transport = 'udp',
    this.stunServer = 'stun:stun.l.google.com:19302',
  })  : _id = id,
        _accountName = accountName;

  String get id => _id.isNotEmpty ? _id : '$extension@$domain';
  String get accountName => _accountName.isNotEmpty
      ? _accountName
      : (displayName.isNotEmpty ? displayName : '$extension@$domain');

  String get sipUri => 'sip:$extension@$domain';

  String get resolvedWebSocketUrl {
    if (!isWebRtc) return '';
    final scheme = transport.toLowerCase() == 'ws' ? 'ws' : 'wss';
    return '$scheme://$domain:$port/ws';
  }

  String get formattedLabel => displayName.isNotEmpty ? '$displayName ($extension)' : extension;

  SipAccount copyWith({
    String? id,
    String? accountName,
    String? extension,
    String? password,
    String? domain,
    String? displayName,
    int? port,
    bool? isWebRtc,
    String? transport,
    String? stunServer,
  }) {
    return SipAccount(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      extension: extension ?? this.extension,
      password: password ?? this.password,
      domain: domain ?? this.domain,
      displayName: displayName ?? this.displayName,
      port: port ?? this.port,
      isWebRtc: isWebRtc ?? this.isWebRtc,
      transport: transport ?? this.transport,
      stunServer: stunServer ?? this.stunServer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountName': accountName,
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
    final ext = map['extension'] ?? '';
    final dom = map['domain'] ?? '';
    return SipAccount(
      id: map['id'] ?? '$ext@$dom',
      accountName: map['accountName'] ?? map['displayName'] ?? '$ext@$dom',
      extension: ext,
      password: map['password'] ?? '',
      domain: dom,
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
