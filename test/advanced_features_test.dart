import 'package:flutter_test/flutter_test.dart';
import 'package:aura_voip/models/call_log_item.dart';
import 'package:aura_voip/services/video_settings_service.dart';

void main() {
  group('CallLogItem Model Tests', () {
    test('CallLogItem with recordingPath serialization and properties', () {
      final now = DateTime.now();
      final item = CallLogItem(
        id: 1,
        phoneNumber: '+15551234567',
        displayName: 'John Doe',
        type: CallLogType.incoming,
        timestamp: now,
        durationSeconds: 125,
        recordingPath: '/storage/recordings/call_1.m4a',
      );

      expect(item.hasRecording, isTrue);
      expect(item.recordingPath, equals('/storage/recordings/call_1.m4a'));
      expect(item.formattedDuration, equals('2m 5s'));

      final map = item.toMap();
      expect(map['recordingPath'], equals('/storage/recordings/call_1.m4a'));
      expect(map['type'], equals('incoming'));

      final restored = CallLogItem.fromMap(map);
      expect(restored.hasRecording, isTrue);
      expect(restored.recordingPath, equals('/storage/recordings/call_1.m4a'));
      expect(restored.displayName, equals('John Doe'));

      final noRecording = item.copyWith(clearRecordingPath: true);
      expect(noRecording.recordingPath, isNull);
      expect(noRecording.hasRecording, isFalse);
    });
  });

  group('VideoSettingsService Constants Tests', () {
    test('Available codecs and defaults are populated', () {
      expect(VideoSettingsService.availableCodecs, contains('VP8 (WebRTC Standard)'));
      expect(VideoSettingsService.availableCodecs, contains('H.264 (Hardware Accelerated)'));
      expect(VideoSettingsService.availableResolutions, contains('720p HD (1280x720)'));
      expect(VideoSettingsService.availableCameras, contains('Front Camera'));
      expect(VideoSettingsService.availableCameras, contains('Back Camera'));
    });
  });
}
