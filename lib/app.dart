import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_container.dart';
import 'presentation/controllers/calendar_controller.dart';
import 'presentation/controllers/review_controller.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/controllers/subscription_controller.dart';
import 'presentation/data_refresh.dart';
import 'presentation/screens/home_shell.dart';
import 'theme.dart';

/// The root widget. It makes the controllers available to every screen
/// (through Provider) and sets the light / dark theme.
class SubCheckApp extends StatefulWidget {
  const SubCheckApp({super.key, required this.container});

  final AppContainer container;

  @override
  State<SubCheckApp> createState() => _SubCheckAppState();
}

class _SubCheckAppState extends State<SubCheckApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ask for notification permission once the first screen is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.container.settingsController.notificationsEnabled) {
        widget.container.reminderScheduler.requestPermission();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When the user comes back to the app (maybe the next day), record any
  /// payment dates that passed and redraw the screens.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.container.reviewController.refreshDuePayments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.container;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataRefresh>.value(value: c.refresh),
        Provider<SubscriptionController>.value(value: c.subscriptionController),
        Provider<ReviewController>.value(value: c.reviewController),
        Provider<CalendarController>.value(value: c.calendarController),
        Provider<SettingsController>.value(value: c.settingsController),
      ],
      child: Consumer<DataRefresh>(
        builder: (context, _, __) => MaterialApp(
          title: 'SubCheck',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: c.settingsController.themeMode,
          home: const HomeShell(),
        ),
      ),
    );
  }
}
