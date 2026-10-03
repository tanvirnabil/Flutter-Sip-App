import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/sip_account.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _activeAccountKey = 'clario_active_sip_account';
  static const _legacyAccountKey = 'aura_active_sip_account';
  static const _accountsListKey = 'clario_all_sip_accounts';
  static const _autoRegisterKey = 'clario_auto_register';

  /// Returns all configured SIP accounts
  static Future<List<SipAccount>> getAllAccounts() async {
    try {
      final listJson = await _storage.read(key: _accountsListKey);
      if (listJson != null && listJson.isNotEmpty) {
        final decoded = json.decode(listJson) as List<dynamic>;
        return decoded
            .map((item) => SipAccount.fromMap(item as Map<String, dynamic>))
            .toList();
      }

      // Fallback: check active or legacy account key and migrate
      final legacy = await getActiveAccount();
      if (legacy != null) {
        final list = [legacy];
        await _saveAccountsList(list);
        return list;
      }
    } catch (_) {}
    return [];
  }

  static Future<void> _saveAccountsList(List<SipAccount> accounts) async {
    try {
      final jsonStr = json.encode(accounts.map((a) => a.toMap()).toList());
      await _storage.write(key: _accountsListKey, value: jsonStr);
    } catch (_) {}
  }

  /// Saves or updates a SIP account in the multi-account registry
  static Future<void> saveAccount(SipAccount account, {bool makeActive = true}) async {
    try {
      final all = await getAllAccounts();
      final index = all.indexWhere((a) => a.id == account.id || (a.extension == account.extension && a.domain == account.domain));

      if (index >= 0) {
        all[index] = account;
      } else {
        all.add(account);
      }

      await _saveAccountsList(all);

      if (makeActive || all.length == 1) {
        await setActiveAccount(account.id);
      }
    } catch (_) {}
  }

  /// Deletes an account by id
  static Future<void> deleteAccount(String id) async {
    try {
      final all = await getAllAccounts();
      all.removeWhere((a) => a.id == id);
      await _saveAccountsList(all);

      final active = await getActiveAccount();
      if (active == null || active.id == id) {
        if (all.isNotEmpty) {
          await setActiveAccount(all.first.id);
        } else {
          await clearAccount();
        }
      }
    } catch (_) {}
  }

  /// Sets the active account by ID
  static Future<void> setActiveAccount(String id) async {
    try {
      final all = await getAllAccounts();
      final match = all.firstWhere(
        (a) => a.id == id,
        orElse: () => all.isNotEmpty ? all.first : const SipAccount(extension: '', password: '', domain: ''),
      );
      if (match.extension.isNotEmpty) {
        final encoded = json.encode(match.toMap());
        await _storage.write(key: _activeAccountKey, value: encoded);
      }
    } catch (_) {}
  }

  /// Gets the currently active SIP account
  static Future<SipAccount?> getActiveAccount() async {
    try {
      var jsonStr = await _storage.read(key: _activeAccountKey);
      jsonStr ??= await _storage.read(key: _legacyAccountKey);

      if (jsonStr == null || jsonStr.isEmpty) {
        final all = await getAllAccounts();
        return all.isNotEmpty ? all.first : null;
      }

      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return SipAccount.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Backward compatible alias for getActiveAccount()
  static Future<SipAccount?> getAccount() => getActiveAccount();

  /// Clears active account
  static Future<void> clearAccount() async {
    try {
      await _storage.delete(key: _activeAccountKey);
      await _storage.delete(key: _legacyAccountKey);
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
