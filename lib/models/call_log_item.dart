import 'package:intl/intl.dart';

enum CallLogType { incoming, outgoing, missed }

class CallLogItem {
  final int? id;
  final String phoneNumber;
  final String displayName;
  final CallLogType type;
  final DateTime timestamp;
  final int durationSeconds;

  const CallLogItem({
    this.id,
    required this.phoneNumber,
    this.displayName = '',
    required this.type,
    required this.timestamp,
    this.durationSeconds = 0,
  });

  String get title => displayName.isNotEmpty ? displayName : phoneNumber;

  String get formattedDuration {
    if (type == CallLogType.missed) return 'Missed';
    if (durationSeconds < 60) return '${durationSeconds}s';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0 && now.day == timestamp.day) {
      return DateFormat('hh:mm a').format(timestamp);
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  factory CallLogItem.fromMap(Map<String, dynamic> map) {
    return CallLogItem(
      id: map['id'] as int?,
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? '',
      type: CallLogType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CallLogType.incoming,
      ),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      durationSeconds: map['durationSeconds'] as int? ?? 0,
    );
  }
}
