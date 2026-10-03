import 'dart:convert';

class ChatMessage {
  final String id;
  final String remoteExtension;
  final String remoteName;
  final String message;
  final DateTime timestamp;
  final bool isOutgoing;
  final bool isDelivered;

  ChatMessage({
    required this.id,
    required this.remoteExtension,
    this.remoteName = '',
    required this.message,
    required this.timestamp,
    required this.isOutgoing,
    this.isDelivered = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remoteExtension': remoteExtension,
      'remoteName': remoteName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isOutgoing': isOutgoing ? 1 : 0,
      'isDelivered': isDelivered ? 1 : 0,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      remoteExtension: map['remoteExtension'] ?? '',
      remoteName: map['remoteName'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isOutgoing: map['isOutgoing'] == 1 || map['isOutgoing'] == true,
      isDelivered: map['isDelivered'] == 1 || map['isDelivered'] == true,
    );
  }

  String toJson() => json.encode(toMap());
  factory ChatMessage.fromJson(String source) => ChatMessage.fromMap(json.decode(source));
}
