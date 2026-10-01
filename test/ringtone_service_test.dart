import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_voip/services/ringtone_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => null);
  });

  group('RingtoneService Tests', () {
    test('Available ringtones include Aura Chime, PBX Bell, and others', () {
      expect(RingtoneService.availableRingtones.length, greaterThanOrEqualTo(5));
      final ids = RingtoneService.availableRingtones.map((r) => r.id).toList();
      expect(ids, contains('aura_chime'));
      expect(ids, contains('pbx_bell'));
      expect(ids, contains('digital_radar'));
      expect(ids, contains('system_default'));
    });

    test('Selecting ringtone updates selected id', () async {
      final service = RingtoneService();
      await service.selectRingtone('pbx_bell');
      expect(service.selectedRingtoneId, equals('pbx_bell'));
      await service.selectRingtone('aura_chime');
      expect(service.selectedRingtoneId, equals('aura_chime'));
    });
  });
}

