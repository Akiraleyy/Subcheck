import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import '../controllers/settings_controller.dart';
import '../data_refresh.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';

/// Figure 9. Settings: Account, Notifications, Appearance, Data & Sync.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<DataRefresh>();
    final settings = context.read<SettingsController>();
    final user = settings.currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('Settings',
            style: TextStyle(
                color: context.ink, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorder)),
          child: Column(children: [
            _item(
              context,
              icon: Icons.person_outline,
              title: 'Account',
              subtitle: user == null
                  ? 'Create or log in to back up your data'
                  : '${user.fullName} · ${user.email}',
              onTap: () => user == null
                  ? Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LogInScreen()))
                  : _accountSheet(context, settings),
            ),
            _item(
              context,
              icon: Icons.notifications_none,
              title: 'Notifications',
              subtitle: settings.notificationsEnabled
                  ? 'Reminders are on'
                  : 'Reminders are off',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const _NotificationsScreen())),
            ),
            _item(
              context,
              icon: Icons.brightness_6_outlined,
              title: 'Appearance',
              subtitle: switch (settings.themeMode) {
                ThemeMode.light => 'Light mode',
                ThemeMode.dark => 'Dark mode',
                ThemeMode.system => 'Follow system',
              },
              onTap: () => _appearanceSheet(context, settings),
            ),
            _item(
              context,
              icon: Icons.sync,
              title: 'Data & Sync',
              subtitle: 'Back up and sync (optional)',
              last: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _DataSyncScreen())),
            ),
          ]),
        ),

        // The orange box that explains the optional backup.
        if (user == null) ...[
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: context.isDark ? AppColors.darkSurface : AppColors.cream,
                borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Icon(Icons.cloud_upload_outlined, color: context.ink, size: 28),
              const SizedBox(height: 8),
              Text(
                'Create an account to back up your data and access it across devices.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.ink, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LogInScreen())),
                child: const Text('Create Account / Log In'),
              ),
              const SizedBox(height: 8),
              Text(
                'Backup is optional but recommended. SubCheck works fully '
                'offline without it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.muted, fontSize: 11),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool last = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: context.cardBorder)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.cardBorder)),
            child: Icon(icon, size: 18, color: context.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(color: context.muted, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.muted),
        ]),
      ),
    );
  }

  void _appearanceSheet(BuildContext context, SettingsController settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system])
            ListTile(
              title: Text(switch (mode) {
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
                ThemeMode.system => 'Follow system',
              }),
              trailing:
                  settings.themeMode == mode ? const Icon(Icons.check) : null,
              onTap: () {
                settings.setThemeMode(mode);
                Navigator.pop(sheetContext);
              },
            ),
        ]),
      ),
    );
  }

  void _accountSheet(BuildContext context, SettingsController settings) {
    final user = settings.currentUser!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user.fullName),
            subtitle: Text(user.email),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.red),
            title:
                const Text('Log out', style: TextStyle(color: AppColors.red)),
            subtitle: const Text('Your subscriptions stay on this phone.'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await settings.logOut();
            },
          ),
        ]),
      ),
    );
  }
}

/// Settings > Notifications: one switch for all reminders.
class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  @override
  Widget build(BuildContext context) {
    context.watch<DataRefresh>();
    final settings = context.read<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(children: [
        SwitchListTile(
          title: const Text('Payment and review reminders'),
          subtitle: const Text(
            'You get a reminder 7 days and 1 day before each payment, plus any '
            '"Review later" reminder you chose. They are saved on your phone, '
            'so they work without internet.',
          ),
          value: settings.notificationsEnabled,
          onChanged: (on) => settings.setNotificationsEnabled(on),
        ),
      ]),
    );
  }
}

/// Settings > Data & Sync: manual backup and restore (needs an account).
class _DataSyncScreen extends StatefulWidget {
  const _DataSyncScreen();

  @override
  State<_DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<_DataSyncScreen> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action, String successMessage) async {
    final settings = context.read<SettingsController>();
    setState(() => _busy = true);
    try {
      final ok = await action();
      if (!mounted) return;
      showSnack(context,
          ok ? successMessage : (settings.errorMessage ?? 'Something went wrong.'));
    } catch (_) {
      if (mounted) {
        showSnack(context,
            'Something went wrong. Check your internet connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<DataRefresh>();
    final settings = context.read<SettingsController>();
    final user = settings.currentUser;
    final lastBackup = settings.lastBackup;

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Sync')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(
          user == null
              ? 'Log in from Settings to back up your data. Without an '
                  'account, everything stays on this phone.'
              : 'Signed in as ${user.email}',
          style: TextStyle(color: context.muted),
        ),
        if (lastBackup != null) ...[
          const SizedBox(height: 8),
          Text('Last backup: ${DateFormat.yMMMd().add_jm().format(lastBackup)}',
              style: TextStyle(
                  color: context.ink, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: user != null && !_busy
              ? () => _run(settings.backupData, 'Backup complete.')
              : null,
          child: Text(_busy ? 'Working…' : 'Back up now'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: user != null && !_busy
              ? () => _run(settings.restoreData, 'Restore finished.')
              : null,
          child: const Text('Restore from backup'),
        ),
        const SizedBox(height: 16),
        Text(
          'Backup needs an internet connection. It never blocks the offline '
          'features.',
          style: TextStyle(color: context.muted, fontSize: 12),
        ),
      ]),
    );
  }
}
