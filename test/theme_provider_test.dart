import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_voip/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider Tests', () {
    test('Default mode is system', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, equals(AppThemeMode.system));
      expect(provider.flutterThemeMode, equals(ThemeMode.system));
      expect(provider.isOled, isFalse);
    });

    test('Switching to OLED mode sets dark theme and isOled flag', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(AppThemeMode.oled);
      expect(provider.themeMode, equals(AppThemeMode.oled));
      expect(provider.flutterThemeMode, equals(ThemeMode.dark));
      expect(provider.isOled, isTrue);
    });

    test('Switching to Light mode sets light theme', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(AppThemeMode.light);
      expect(provider.themeMode, equals(AppThemeMode.light));
      expect(provider.flutterThemeMode, equals(ThemeMode.light));
      expect(provider.isOled, isFalse);
    });
  });
}
