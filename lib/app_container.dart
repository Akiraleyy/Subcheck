import 'package:flutter/foundation.dart';

import 'cloud_sync/firebase_client.dart';
import 'cloud_sync/mock_firebase_client.dart';
import 'cloud_sync/sync_service.dart';
import 'data_access/local_database.dart';
import 'data_access/logo_store.dart';
import 'data_access/payment_repository.dart';
import 'data_access/review_repository.dart';
import 'data_access/reminder_repository.dart';
import 'data_access/settings_repository.dart';
import 'data_access/subscription_repository.dart';
import 'notification/notification_sender.dart';
import 'notification/reminder_scheduler.dart';
import 'presentation/controllers/calendar_controller.dart';
import 'presentation/controllers/review_controller.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/controllers/subscription_controller.dart';
import 'presentation/data_refresh.dart';
import 'review_management/calendar_service.dart';
import 'review_management/review_policy.dart';
import 'review_management/review_service.dart';
import 'subscription_management/cost_calculator.dart';
import 'subscription_management/subscription_service.dart';

/// Builds every object of the app ONCE and connects them, bottom to top,
/// exactly like the boxes of the High-Level Design (Figure 1):
///
///   Local Database -> repositories (Data Access) -> Notification ->
///   Subscription Management -> Review Management -> controllers (Presentation)
///   and the optional Cloud Sync on the side.
///
/// Each class receives the classes it needs through its constructor. That is
/// what the "uses" attributes in the Low-Level Design (Figure 2) mean.
class AppContainer {
  AppContainer._({
    required this.refresh,
    required this.subscriptionController,
    required this.reviewController,
    required this.calendarController,
    required this.settingsController,
    required this.reminderScheduler,
  });

  final DataRefresh refresh;
  final SubscriptionController subscriptionController;
  final ReviewController reviewController;
  final CalendarController calendarController;
  final SettingsController settingsController;
  final ReminderScheduler reminderScheduler;

  static Future<AppContainer> create() async {
    // ---- Local Database + Data Access Module ----
    final database = LocalDatabase();
    await database.open();

    final subscriptionRepository = SubscriptionRepository(database)..load();
    final reviewRepository = ReviewRepository(database)..load();
    final paymentRepository = PaymentRepository(database)..load();
    final reminderRepository = ReminderRepository(database)..load();
    final settingsRepository = SettingsRepository(database);
    final logoStore = LogoStore();

    // ---- Notification Module ----
    final notificationSender = NotificationSender()
      ..enabled = settingsRepository.notificationsEnabled;
    const reviewPolicy = ReviewPolicy();
    final reminderScheduler = ReminderScheduler(
      reminderRepository: reminderRepository,
      notificationSender: notificationSender,
      subscriptionRepository: subscriptionRepository,
      renewalLeadDays: reviewPolicy.getReviewWindowDays(),
    );

    // ---- Subscription Management Module ----
    const costCalculator = CostCalculator();
    final subscriptionService = SubscriptionService(
      subscriptionRepository: subscriptionRepository,
      reminderScheduler: reminderScheduler,
      reviewRepository: reviewRepository,
      paymentRepository: paymentRepository,
      logoStore: logoStore,
    );

    // ---- Review Management Module ----
    final reviewService = ReviewService(
      reviewRepository: reviewRepository,
      subscriptionRepository: subscriptionRepository,
      reviewPolicy: reviewPolicy,
      reminderScheduler: reminderScheduler,
      paymentRepository: paymentRepository,
      costCalculator: costCalculator,
    );
    final calendarService = CalendarService(
      paymentRepository: paymentRepository,
      reviewRepository: reviewRepository,
      subscriptionRepository: subscriptionRepository,
    );

    // ---- Cloud Sync Module (optional) ----
    // MockFirebaseClient pretends to be the cloud. To use real Firebase,
    // follow FIREBASE_SETUP.md and replace the next line with
    //   final FirebaseClient firebaseClient = RealFirebaseClient();
    final FirebaseClient firebaseClient = MockFirebaseClient(database);
    final syncService = SyncService(
      firebaseClient: firebaseClient,
      subscriptionRepository: subscriptionRepository,
      reviewRepository: reviewRepository,
      paymentRepository: paymentRepository,
      settingsRepository: settingsRepository,
    );

    // ---- Presentation Module (controllers) ----
    final refresh = DataRefresh();
    final settingsController = SettingsController(
      syncService: syncService,
      settingsRepository: settingsRepository,
      reminderScheduler: reminderScheduler,
      refresh: refresh,
    );
    // After a restore: record payments that passed, then rebuild reminders.
    settingsController.afterRestore = () async {
      await reviewService.processDuePayments();
      await reminderScheduler
          .rebuildAll(subscriptionService.getAllSubscriptions());
    };

    final container = AppContainer._(
      refresh: refresh,
      subscriptionController: SubscriptionController(
        subscriptionService: subscriptionService,
        costCalculator: costCalculator,
        reviewService: reviewService,
        refresh: refresh,
      ),
      reviewController:
          ReviewController(reviewService: reviewService, refresh: refresh),
      calendarController: CalendarController(calendarService: calendarService),
      settingsController: settingsController,
      reminderScheduler: reminderScheduler,
    );

    // ---- Start-up tasks ----
    // If one of these fails the app should still open, so errors are caught.
    try {
      await reviewService.processDuePayments();
      await reminderScheduler.markDueRemindersAsSent();
      await reminderScheduler.rescheduleAll();
    } catch (e) {
      debugPrint('Start-up task failed: $e');
    }

    return container;
  }
}
