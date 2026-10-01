import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_voip/services/dtmf_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => null);
  });

  group('DtmfAudioService Tests', () {
    test('Service instance can be initialized', () async {
      final service = DtmfAudioService();
      expect(service, isNotNull);
      expect(service.isEnabled, isTrue);
    });

    test('Toggling DTMF state works', () async {
      final service = DtmfAudioService();
      await service.setEnabled(false);
      expect(service.isEnabled, isFalse);
      await service.setEnabled(true);
      expect(service.isEnabled, isTrue);
    });
  });
}

