import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// HLD box: "Local Database". The storage on the user's phone.
///
/// It keeps "tables" (lists of rows) and single values as text on the device,
/// so everything survives closing the app or restarting the phone, and works
/// without internet. Only the repositories in this folder use this class, so
/// the rest of the app never touches storage directly.
///
/// To switch to SQLite later, only this file and the repositories change.
class LocalDatabase {
  SharedPreferences? _prefs;

  /// Must be called once before anything else (done in AppContainer).
  Future<void> open() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('LocalDatabase.open() has not been called yet.');
    }
    return prefs;
  }

  /// Reads all rows of a table. Returns an empty list if there is nothing
  /// saved yet, or if the saved text is damaged (so the app never crashes).
  List<Map<String, dynamic>> readTable(String table) {
    final raw = _p.getString(table);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Replaces all rows of a table.
  Future<void> writeTable(String table, List<Map<String, dynamic>> rows) async {
    await _p.setString(table, jsonEncode(rows));
  }

  String? readString(String key) => _p.getString(key);

  /// Saving null removes the key.
  Future<void> writeString(String key, String? value) async {
    if (value == null) {
      await _p.remove(key);
    } else {
      await _p.setString(key, value);
    }
  }

  bool? readBool(String key) => _p.getBool(key);

  Future<void> writeBool(String key, bool value) async {
    await _p.setBool(key, value);
  }
}
