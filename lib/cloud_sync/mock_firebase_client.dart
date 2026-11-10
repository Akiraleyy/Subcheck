import 'dart:convert';

import '../data_access/local_database.dart';
import '../utils/helpers.dart';
import 'backup_data.dart';
import 'firebase_client.dart';
import 'user_account.dart';

/// A stand-in for Firebase so the app is fully demonstrable offline.
///
/// It keeps its "cloud" accounts and backups inside the phone's storage.
/// That means create account, log in, back up and restore all really work,
/// and survive restarting the app. But the data never leaves the phone, and
/// passwords are stored as plain text here, which is fine for a demo but is
/// why the real Firebase client (FIREBASE_SETUP.md) should be used for real.
class MockFirebaseClient implements FirebaseClient {
  MockFirebaseClient(this._db);

  final LocalDatabase _db;
  String? _lastError;
  UserAccount? _account;

  static const _usersTable = 'mock_cloud_users';
  static const _backupPrefix = 'mock_cloud_backup_';

  @override
  String? get lastError => _lastError;

  @override
  UserAccount? get account => _account;

  Future<void> _pretendToUseTheInternet() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<bool> signUp(String name, String email, String password) async {
    _lastError = null;
    await _pretendToUseTheInternet();
    final users = _db.readTable(_usersTable);
    final key = email.trim().toLowerCase();
    if (users.any((u) => u['email'] == key)) {
      _lastError = 'An account with this email already exists.';
      return false;
    }
    final uid = newUuid();
    users.add({
      'uid': uid,
      'fullName': name.trim(),
      'email': key,
      'password': password,
    });
    await _db.writeTable(_usersTable, users);
    _account = UserAccount(uid: uid, fullName: name.trim(), email: key);
    return true;
  }

  @override
  Future<bool> signIn(String email, String password) async {
    _lastError = null;
    await _pretendToUseTheInternet();
    final key = email.trim().toLowerCase();
    for (final u in _db.readTable(_usersTable)) {
      if (u['email'] == key && u['password'] == password) {
        _account = UserAccount(
          uid: u['uid'] as String,
          fullName: u['fullName'] as String,
          email: key,
        );
        return true;
      }
    }
    _lastError = 'Incorrect email or password.';
    return false;
  }

  @override
  Future<void> signOut() async {
    _account = null;
  }

  @override
  Future<bool> uploadData(String userId, BackupData data) async {
    _lastError = null;
    await _pretendToUseTheInternet();
    await _db.writeString('$_backupPrefix$userId', jsonEncode(data.toJson()));
    return true;
  }

  @override
  Future<BackupData?> downloadData(String userId) async {
    _lastError = null;
    await _pretendToUseTheInternet();
    final raw = _db.readString('$_backupPrefix$userId');
    if (raw == null) return null;
    try {
      return BackupData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _lastError = 'The backup could not be read.';
      return null;
    }
  }
}
