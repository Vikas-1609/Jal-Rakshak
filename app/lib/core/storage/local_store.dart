import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences, loaded once in main() and injected with an override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main() after loading'),
);

final localStoreProvider = Provider(
  (ref) => LocalStore(ref.watch(sharedPreferencesProvider)),
);

/// Small JSON key-value store on the phone, for settings and cached results.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  int countWithPrefix(String prefix) =>
      _prefs.getKeys().where((k) => k.startsWith(prefix)).length;

  Future<void> removeWithPrefix(String prefix) async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await _prefs.remove(k);
    }
  }
}
