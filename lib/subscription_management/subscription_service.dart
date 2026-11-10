import '../data_access/logo_store.dart';
import '../data_access/models/subscription.dart';
import '../data_access/models/validation.dart';
import '../data_access/payment_repository.dart';
import '../data_access/review_repository.dart';
import '../data_access/subscription_repository.dart';
import '../notification/reminder_scheduler.dart';
import '../utils/helpers.dart';

/// LLD class: SubscriptionService. Adds, edits and deletes subscriptions and
/// checks that their details are valid.
class SubscriptionService {
  SubscriptionService({
    required this.subscriptionRepository,
    required this.reminderScheduler,
    required this.reviewRepository,
    required this.paymentRepository,
    required this.logoStore,
  });

  final SubscriptionRepository subscriptionRepository;
  final ReminderScheduler reminderScheduler;

  // Added: only used to clean up history when a subscription is deleted.
  final ReviewRepository reviewRepository;
  final PaymentRepository paymentRepository;
  final LogoStore logoStore;

  /// "Upcoming payments" on the dashboard = due within this many days.
  static const int upcomingWindowDays = 14;

  Future<Subscription> addSubscription(Subscription subscription) async {
    _ensureValid(subscription);
    final saved = await subscriptionRepository.insert(subscription);
    await reminderScheduler.scheduleRenewalReminder(saved);
    return saved;
  }

  Future<Subscription> updateSubscription(
      String id, Subscription subscription) async {
    final old = subscriptionRepository.findById(id);
    if (old == null) throw StateError('Subscription not found.');
    _ensureValid(subscription);
    await subscriptionRepository.update(subscription);
    // A new payment date makes old "review later" reminders meaningless.
    if (!isSameDay(old.nextPaymentDate, subscription.nextPaymentDate)) {
      await reminderScheduler.cancelReminders(id);
    }
    await reminderScheduler.scheduleRenewalReminder(subscription);
    return subscription;
  }

  /// Deletes the subscription, its reminders and its history.
  Future<bool> deleteSubscription(String id) async {
    await reminderScheduler.cancelReminders(id);
    await reviewRepository.deleteBySubscription(id);
    await paymentRepository.deleteBySubscription(id);
    return subscriptionRepository.delete(id);
  }

  Subscription? getSubscription(String id) =>
      subscriptionRepository.findById(id);

  List<Subscription> getAllSubscriptions() => subscriptionRepository.findAll();

  /// Added: active subscriptions due within [upcomingWindowDays], soonest first.
  List<Subscription> getUpcomingSubscriptions(DateTime today) {
    final list = subscriptionRepository.findAll().where((s) {
      if (!s.isActive) return false;
      final days = daysBetween(today, s.nextPaymentDate);
      return days >= 0 && days <= upcomingWindowDays;
    }).toList();
    list.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return list;
  }

  /// Added: saves the picked logo into the app's own folder.
  Future<String?> saveLogo(String? pickedPath) => logoStore.save(pickedPath);

  /// Checks the details a user typed in. Returns every problem found.
  ValidationResult validateSubscription(Subscription subscription) {
    final errors = <ValidationError>[];

    if (subscription.name.trim().isEmpty) {
      errors.add(const ValidationError(
          code: 'required',
          field: 'name',
          message: 'Enter the subscription name.'));
    } else if (subscription.name.trim().length > 40) {
      errors.add(const ValidationError(
          code: 'too_long',
          field: 'name',
          message: 'Use 40 characters or fewer.'));
    }

    if (subscription.price <= 0) {
      errors.add(const ValidationError(
          code: 'invalid',
          field: 'price',
          message: 'Enter a price greater than 0.'));
    }

    if (subscription.isShared && subscription.numberOfPeople < 2) {
      errors.add(const ValidationError(
          code: 'invalid',
          field: 'numberOfPeople',
          message: 'Enter 2 or more people.'));
    }

    return ValidationResult(errors);
  }

  void _ensureValid(Subscription subscription) {
    final result = validateSubscription(subscription);
    if (!result.valid) throw ValidationException(result);
  }
}
