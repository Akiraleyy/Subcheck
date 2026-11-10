import '../data_access/models/enums.dart';
import '../data_access/models/payment_record.dart';
import '../data_access/models/reminder.dart';
import '../data_access/models/review_record.dart';
import '../data_access/models/subscription.dart';
import '../data_access/payment_repository.dart';
import '../data_access/review_repository.dart';
import '../data_access/subscription_repository.dart';
import '../notification/reminder_scheduler.dart';
import '../subscription_management/cost_calculator.dart';
import '../utils/helpers.dart';
import 'review_policy.dart';

/// LLD class: ReviewService. Handles Keep, Review later and Stop tracking,
/// and finds which subscriptions are waiting for a decision.
class ReviewService {
  ReviewService({
    required this.reviewRepository,
    required this.subscriptionRepository,
    required this.reviewPolicy,
    required this.reminderScheduler,
    required this.paymentRepository,
    required this.costCalculator,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ReviewRepository reviewRepository;
  final SubscriptionRepository subscriptionRepository;
  final ReviewPolicy reviewPolicy;
  final ReminderScheduler reminderScheduler;

  // Added: needed to record payments when a payment date passes.
  final PaymentRepository paymentRepository;
  final CostCalculator costCalculator;

  final DateTime Function() _now;

  /// Subscriptions that need a decision, soonest payment first.
  List<Subscription> getSubscriptionsForReview() {
    final today = dateOnly(_now());
    final list = subscriptionRepository
        .findAll()
        .where((s) => _isWaitingForReview(s, today))
        .toList();
    list.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return list;
  }

  bool _isWaitingForReview(Subscription s, DateTime today) {
    // Rule 1: the payment must be inside the review window.
    if (!reviewPolicy.needsReview(s, today)) return false;

    // Decisions the user already made for THIS payment date.
    final records = reviewRepository
        .findBySubscription(s.id)
        .where((r) => !r.isMissed && isSameDay(r.paymentDate, s.nextPaymentDate))
        .toList();

    // Rule 2: already kept for this payment, so nothing more to decide.
    if (records.any((r) => r.decision == ReviewDecision.keep)) return false;

    // Rule 3: snoozed with "Review later" and the chosen day has not come yet.
    final snoozes = records
        .where((r) =>
            r.decision == ReviewDecision.reviewLater &&
            r.remindAgainDate != null)
        .toList();
    if (snoozes.isNotEmpty) {
      snoozes.sort((a, b) => a.reviewDate.compareTo(b.reviewDate));
      final remindOn = dateOnly(snoozes.last.remindAgainDate!);
      if (remindOn.isAfter(today)) return false;
    }
    return true;
  }

  /// Keep: continue tracking this subscription.
  Future<ReviewRecord> keepSubscription(String id) async {
    final s = _require(id);
    // A "review later" reminder is no longer needed once the user has kept it.
    await reminderScheduler.cancelReminders(id, type: ReminderType.review);
    return reviewRepository.insert(ReviewRecord(
      id: newUuid(),
      subscriptionId: id,
      decision: ReviewDecision.keep,
      reviewDate: _now(),
      paymentDate: dateOnly(s.nextPaymentDate),
    ));
  }

  /// Review later: remind the user again in [days] days (1, 3 or 5), which
  /// must be a day BEFORE the payment.
  Future<ReviewRecord> reviewLater(String id, int days) async {
    final s = _require(id);
    final options = reviewPolicy.getReminderOptions();
    if (!options.contains(days)) {
      throw ArgumentError('Choose one of $options days.');
    }
    final remindOn = addDays(dateOnly(_now()), days);
    if (!remindOn.isBefore(dateOnly(s.nextPaymentDate))) {
      throw StateError('Pick a day before the next payment.');
    }
    await reminderScheduler.rescheduleReminder(id, days);
    return reviewRepository.insert(ReviewRecord(
      id: newUuid(),
      subscriptionId: id,
      decision: ReviewDecision.reviewLater,
      reviewDate: _now(),
      remindAgainDate: remindOn,
      paymentDate: dateOnly(s.nextPaymentDate),
    ));
  }

  /// Stop tracking: SubCheck stops tracking and reminding. This does NOT
  /// cancel the real subscription; the user must do that with the service.
  Future<ReviewRecord> stopTracking(String id) async {
    final s = _require(id);
    await subscriptionRepository
        .update(s.copyWith(status: SubscriptionStatus.stopped));
    await reminderScheduler.cancelReminders(id);
    return reviewRepository.insert(ReviewRecord(
      id: newUuid(),
      subscriptionId: id,
      decision: ReviewDecision.stopTracking,
      reviewDate: _now(),
      paymentDate: dateOnly(s.nextPaymentDate),
    ));
  }

  /// Reviews the user never answered before the payment date.
  List<ReviewRecord> getMissedReviews() => reviewRepository.findMissed();

  /// Added: runs at start-up and whenever the app comes back to the screen.
  ///
  /// SubCheck cannot see the user's bank, so when a payment date passes it
  /// assumes the payment happened. For each passed date it:
  ///   1. saves a PaymentRecord (green on the calendar),
  ///   2. saves a missed ReviewRecord if the user never chose Keep (red),
  ///   3. moves the subscription to its next payment date and re-plans reminders.
  /// Returns how many payments were recorded.
  Future<int> processDuePayments() async {
    final today = dateOnly(_now());
    var recorded = 0;

    for (final original
        in subscriptionRepository.findAll().where((s) => s.isActive)) {
      var current = original;
      var changed = false;
      var guard = 0; // safety stop so a bad date can never loop forever

      while (dateOnly(current.nextPaymentDate).isBefore(today) && guard < 500) {
        final due = dateOnly(current.nextPaymentDate);

        await paymentRepository.insert(PaymentRecord(
          id: newUuid(),
          subscriptionId: current.id,
          amount: costCalculator.getUserShare(current),
          paymentDate: due,
          isPaid: true,
        ));

        final wasKept = reviewRepository.findBySubscription(current.id).any(
            (r) => r.decision == ReviewDecision.keep && isSameDay(r.paymentDate, due));
        if (!wasKept) {
          await reviewRepository.insert(ReviewRecord(
            id: newUuid(),
            subscriptionId: current.id,
            decision: null, // null = missed review
            reviewDate: due,
            paymentDate: due,
          ));
        }

        current = current.copyWith(
            nextPaymentDate: addCycle(due, current.billingCycle));
        changed = true;
        recorded++;
        guard++;
      }

      if (changed) {
        await subscriptionRepository.update(current);
        await reminderScheduler.cancelReminders(current.id);
        await reminderScheduler.scheduleRenewalReminder(current);
      }
    }
    return recorded;
  }

  Subscription _require(String id) {
    final s = subscriptionRepository.findById(id);
    if (s == null) throw StateError('Subscription not found.');
    return s;
  }
}
