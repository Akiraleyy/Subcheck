import 'package:flutter/material.dart';

import '../../cloud_sync/sync_service.dart';
import '../../cloud_sync/user_account.dart';
import '../../data_access/settings_repository.dart';
import '../../notification/reminder_scheduler.dart';
import '../data_refresh.dart';

/// LLD class: SettingsController. Receives taps from the Settings screens:
/// account, backup, notifications and appearance.
class SettingsController {
  SettingsController({
    required this.syncService,
    required this.settingsRepository,
    required this.reminderScheduler,
    required this.refresh,
    this.afterRestore,
  });

  final SyncService syncService;

  // Added: needed for the Notifications and Appearance rows of Figure 9.
  final SettingsRepository settingsRepository;
  final ReminderScheduler reminderScheduler;
  final DataRefresh refresh;

  /// Runs after a successful restore (set in AppContainer). It records any
  /// payments that passed and rebuilds the reminders.
  Future<void> Function()? afterRestore;

  // ---------------- account and backup (LLD methods) ----------------

  UserAccount? get currentUser => syncService.currentUser;

  /// A message explaining why the last action failed.
  String? get errorMessage => syncService.lastError;

  DateTime? get lastBackup => settingsRepository.lastBackup;

  Future<bool> createAccount(String name, String email, String password) async {
    final ok = await syncService.createAccount(name, email, password);
    refresh.notifyChanged();
    return ok;
  }

  Future<bool> logIn(String email, String password) async {
    final ok = await syncService.logIn(email, password);
    refresh.notifyChanged();
    return ok;
  }

  Future<void> logOut() async {
    await syncService.logOut();
    refresh.notifyChanged();
  }

  Future<bool> backupData() async {
    final ok = await syncService.backupData();
    refresh.notifyChanged();
    return ok;
  }

  Future<bool> restoreData() async {
    final ok = await syncService.restoreData();
    if (ok && afterRestore != null) {
      await afterRestore!();
    }
    refresh.notifyChanged();
    return ok;
  }

  // ---------------- appearance ----------------

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[settingsRepository.themeModeName] ??
      ThemeMode.light;

  Future<void> setThemeMode(ThemeMode mode) async {
    await settingsRepository.saveThemeModeName(mode.name);
    refresh.notifyChanged();
  }

  // ---------------- notifications ----------------

  bool get notificationsEnabled => settingsRepository.notificationsEnabled;

  Future<void> setNotificationsEnabled(bool on) async {
    await settingsRepository.saveNotificationsEnabled(on);
    reminderScheduler.enabled = on;
    if (on) {
      await reminderScheduler.requestPermission();
      await reminderScheduler.rescheduleAll();
    } else {
      await reminderScheduler.cancelAllNotifications();
    }
    refresh.notifyChanged();
  }
}
