import 'dart:convert';

import '../cloud_sync/user_account.dart';
import 'local_database.dart';

/// Not in the LLD diagram, but the Settings screen (Figure 9) needs to
/// remember a few small choices. Like every repository, it is the only
/// code that talks to the Local Database for these values.
class SettingsRepository {
  SettingsRepository(this._db);

  final LocalDatabase _db;

  /// "light", "dark" or "system".
  String get themeModeName => _db.readString('theme_mode') ?? 'light';
  Future<void> saveThemeModeName(String name) =>
      _db.writeString('theme_mode', name);

  bool get notificationsEnabled => _db.readBool('notifications_enabled') ?? true;
  Future<void> saveNotificationsEnabled(bool value) =>
      _db.writeBool('notifications_enabled', value);

  DateTime? get lastBackup {
    final raw = _db.readString('last_backup');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveLastBackup(DateTime? value) =>
      _db.writeString('last_backup', value?.toIso8601String());

  /// The signed-in account, or null when the user never logged in.
  UserAccount? get currentUser {
    final raw = _db.readString('current_user');
    if (raw == null) return null;
    try {
      return UserAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCurrentUser(UserAccount? user) =>
      _db.writeString('current_user', user == null ? null : jsonEncode(user.toJson()));
}
