import '../data_access/models/reminder.dart';
import '../data_access/models/subscription.dart';
import '../data_access/reminder_repository.dart';
import '../data_access/subscription_repository.dart';
import '../subscription_management/cost_calculator.dart';
import '../utils/helpers.dart';
import 'notification_sender.dart';

/// LLD class: ReminderScheduler. Decides WHEN reminders happen, saves them,
/// and asks NotificationSender to show them.
///
/// Reminders for a subscription (all at 9:00 AM):
///  * 7 days before the payment: "renews in 7 days" (time to review)
///  * 1 day before the payment: "payment tomorrow"
///  * the day the user chose in "Review later"
class ReminderScheduler {
  ReminderScheduler({
    required this.reminderRepository,
    required this.notificationSender,
    required this.subscriptionRepository,
    this.renewalLeadDays = 7,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ReminderRepository reminderRepository;
  final NotificationSender notificationSender;

  /// Added: used to look up a subscription's name for the message text.
  final SubscriptionRepository subscriptionRepository;

  /// How many days before the payment the renewal reminder is sent.
  /// The container passes ReviewPolicy.getReviewWindowDays() here.
  final int renewalLeadDays;

  static const int reminderHour = 9;
  final DateTime Function() _now;

  set enabled(bool value) => notificationSender.enabled = value;

  Future<bool> requestPermission() => notificationSender.requestPermission();

  /// Plans the renewal reminder (7 days before) and the payment reminder
  /// (1 day before) for [subscription], replacing any old ones.
  ///
  /// Returns the renewal reminder, or null when that moment has already
  /// passed (for example a subscription due in 4 days).
  Future<Reminder?> scheduleRenewalReminder(Subscription subscription) async {
    await cancelReminders(subscription.id, type: ReminderType.renewal);
    await cancelReminders(subscription.id, type: ReminderType.payment);
    if (!subscription.isActive) return null;

    final pay = dateOnly(subscription.nextPaymentDate);
    final share = peso(const CostCalculator().getUserShare(subscription));
    final renewalAt =
        DateTime(pay.year, pay.month, pay.day - renewalLeadDays, reminderHour);
    final paymentAt = DateTime(pay.year, pay.month, pay.day - 1, reminderHour);

    Reminder? renewal;
    if (renewalAt.isAfter(_now())) {
      renewal = await _create(
        subscription.id,
        renewalAt,
        ReminderType.renewal,
        '${subscription.name} renews in $renewalLeadDays days',
        '$share is due soon. Open SubCheck to keep it, review it later, or stop tracking it.',
      );
    }
    if (paymentAt.isAfter(_now())) {
      await _create(
        subscription.id,
        paymentAt,
        ReminderType.payment,
        '${subscription.name} payment tomorrow',
        '$share will be charged tomorrow.',
      );
    }
    return renewal;
  }

  /// Plans a "Review later" reminder [days] days from today (1, 3 or 5).
  Future<Reminder> rescheduleReminder(String subscriptionId, int days) async {
    await cancelReminders(subscriptionId, type: ReminderType.review);
    final name = subscriptionRepository.findById(subscriptionId)?.name ??
        'your subscription';
    final today = dateOnly(_now());
    final when =
        DateTime(today.year, today.month, today.day + days, reminderHour);
    return _create(
      subscriptionId,
      when,
      ReminderType.review,
      'Time to review $name',
      'Do you still want to keep $name? Open SubCheck to decide.',
    );
  }

  /// Removes a subscription's reminders from the phone and from storage.
  /// If [type] is given, only that kind is removed.
  Future<bool> cancelReminders(String subscriptionId, {String? type}) async {
    final existing = reminderRepository
        .findBySubscription(subscriptionId)
        .where((r) => type == null || r.type == type)
        .toList();
    for (final reminder in existing) {
      await notificationSender.cancel(reminder);
    }
    return reminderRepository.deleteBySubscription(subscriptionId, type: type);
  }

  /// Hands every saved future reminder to the phone again. Called at start-up
  /// and when notifications are switched back on.
  Future<void> rescheduleAll() async {
    final now = _now();
    for (final reminder in reminderRepository.findAll()) {
      if (!reminder.isSent && reminder.scheduledDate.isAfter(now)) {
        await notificationSender.showNotification(reminder);
      }
    }
  }

  /// Wipes all reminders and plans fresh ones. Used after a restore.
  Future<void> rebuildAll(List<Subscription> subscriptions) async {
    await notificationSender.cancelAll();
    await reminderRepository.deleteAll();
    for (final s in subscriptions) {
      await scheduleRenewalReminder(s);
    }
  }

  Future<void> cancelAllNotifications() => notificationSender.cancelAll();

  /// Marks reminders whose time has passed as sent (housekeeping).
  Future<void> markDueRemindersAsSent() async {
    for (final reminder in reminderRepository.findDue(_now())) {
      await reminderRepository.update(reminder.copyWith(isSent: true));
    }
  }

  Future<Reminder> _create(
    String subscriptionId,
    DateTime when,
    String type,
    String title,
    String body,
  ) async {
    final reminder = Reminder(
      id: newUuid(),
      subscriptionId: subscriptionId,
      scheduledDate: when,
      type: type,
      isSent: false,
      title: title,
      body: body,
    );
    await reminderRepository.insert(reminder);
    await notificationSender.showNotification(reminder);
    return reminder;
  }
}
