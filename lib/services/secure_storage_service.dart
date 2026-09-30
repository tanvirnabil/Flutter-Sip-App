import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/sip_account.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _activeAccountKey = 'aura_active_sip_account';
  static const _autoRegisterKey = 'aura_auto_register';

  static Future<void> saveAccount(SipAccount account) async {
    try {
      await _storage.write(
        key: _activeAccountKey,
        value: json.encode(account.toMap()),
      );
    } catch (_) {}
  }

  static Future<SipAccount?> getAccount() async {
    try {
      final jsonStr = await _storage.read(key: _activeAccountKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return SipAccount.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAccount() async {
    try {
      await _storage.delete(key: _activeAccountKey);
    } catch (_) {}
  }

  static Future<void> setAutoRegister(bool enabled) async {
    await _storage.write(key: _autoRegisterKey, value: enabled.toString());
  }

  static Future<bool> isAutoRegisterEnabled() async {
    final value = await _storage.read(key: _autoRegisterKey);
    return value == 'true';
  }
}
