enum AuraCallDirection { incoming, outgoing }

enum AuraCallStatus {
  idle,
  connecting,
  ringing,
  active,
  held,
  ended,
}

class CallSessionModel {
  final String id;
  final String targetNumber;
  final String targetName;
  final AuraCallDirection direction;
  final AuraCallStatus status;
  final int durationSeconds;
  final bool isMuted;
  final bool isSpeaker;
  final bool isOnHold;
  final DateTime? startedAt;

  const CallSessionModel({
    required this.id,
    required this.targetNumber,
    this.targetName = '',
    required this.direction,
    this.status = AuraCallStatus.idle,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeaker = false,
    this.isOnHold = false,
    this.startedAt,
  });

  String get displayName => targetName.isNotEmpty ? targetName : targetNumber;

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  CallSessionModel copyWith({
    String? id,
    String? targetNumber,
    String? targetName,
    AuraCallDirection? direction,
    AuraCallStatus? status,
    int? durationSeconds,
    bool? isMuted,
    bool? isSpeaker,
    bool? isOnHold,
    DateTime? startedAt,
  }) {
    return CallSessionModel(
      id: id ?? this.id,
      targetNumber: targetNumber ?? this.targetNumber,
      targetName: targetName ?? this.targetName,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isSpeaker: isSpeaker ?? this.isSpeaker,
      isOnHold: isOnHold ?? this.isOnHold,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
