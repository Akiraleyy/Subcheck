import '../../data_access/models/dashboard_summary.dart';
import '../../data_access/models/enums.dart';
import '../../data_access/models/subscription.dart';
import '../../data_access/models/validation.dart';
import '../../review_management/review_service.dart';
import '../../subscription_management/cost_calculator.dart';
import '../../subscription_management/subscription_service.dart';
import '../../utils/helpers.dart';
import '../data_refresh.dart';

/// What the Add / Edit form collects. Some fields can be null because the
/// user may leave them empty; validate() reports those.
class SubscriptionData {
  const SubscriptionData({
    required this.name,
    required this.category,
    required this.price,
    required this.billingCycle,
    required this.nextPaymentDate,
    this.logoPath,
    this.isShared = false,
    this.numberOfPeople = 1,
  });

  final String name;
  final Category category;
  final double? price;
  final BillingCycle billingCycle;
  final DateTime? nextPaymentDate;
  final String? logoPath;
  final bool isShared;
  final int numberOfPeople;
}

/// LLD class: SubscriptionController. Receives the user's taps from the
/// Home, Add and Details screens and passes them to the services.
class SubscriptionController {
  SubscriptionController({
    required this.subscriptionService,
    required this.costCalculator,
    required this.reviewService,
    required this.refresh,
  });

  final SubscriptionService subscriptionService;
  final CostCalculator costCalculator;

  /// Added: the dashboard also shows how many subscriptions need review.
  final ReviewService reviewService;
  final DataRefresh refresh;

  /// Checks a form before saving. The screen shows each message under its field.
  ValidationResult validate(SubscriptionData data) {
    final errors = <ValidationError>[];
    final price = data.price;
    final date = data.nextPaymentDate;

    if (price == null) {
      errors.add(const ValidationError(
          code: 'invalid',
          field: 'price',
          message: 'Enter a price greater than 0.'));
    }
    if (date == null) {
      errors.add(const ValidationError(
          code: 'required',
          field: 'nextPaymentDate',
          message: 'Choose the next payment date.'));
    }

    // Let the service check name, price and number of people as well.
    final draft = _build(
      id: 'draft',
      data: data,
      price: price ?? 0,
      date: date ?? DateTime.now(),
      logoPath: data.logoPath,
      status: SubscriptionStatus.active,
    );
    for (final error in subscriptionService.validateSubscription(draft).errors) {
      if (!errors.any((e) => e.field == error.field)) errors.add(error);
    }
    return ValidationResult(errors);
  }

  Future<Subscription> addSubscription(SubscriptionData data) async {
    _ensureValid(data);
    final logo = await subscriptionService.saveLogo(data.logoPath);
    final subscription = _build(
      id: newUuid(),
      data: data,
      price: data.price!,
      date: data.nextPaymentDate!,
      logoPath: logo,
      status: SubscriptionStatus.active,
    );
    final saved = await subscriptionService.addSubscription(subscription);
    refresh.notifyChanged();
    return saved;
  }

  Future<Subscription> editSubscription(String id, SubscriptionData data) async {
    _ensureValid(data);
    final existing = subscriptionService.getSubscription(id);
    if (existing == null) throw StateError('Subscription not found.');

    // Only copy the image again if the user picked a different one.
    final logo = data.logoPath == existing.logoPath
        ? existing.logoPath
        : await subscriptionService.saveLogo(data.logoPath);

    final updated = _build(
      id: id,
      data: data,
      price: data.price!,
      date: data.nextPaymentDate!,
      logoPath: logo,
      status: existing.status,
    );
    final saved = await subscriptionService.updateSubscription(id, updated);
    refresh.notifyChanged();
    return saved;
  }

  Future<bool> deleteSubscription(String id) async {
    final ok = await subscriptionService.deleteSubscription(id);
    refresh.notifyChanged();
    return ok;
  }

  /// Every subscription (active and stopped), soonest payment first.
  List<Subscription> getSubscriptions() {
    final list = subscriptionService.getAllSubscriptions();
    list.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return list;
  }

  Subscription? getSubscription(String id) =>
      subscriptionService.getSubscription(id);

  /// Builds everything the Home screen shows (Figure 1).
  DashboardSummary getDashboardSummary() {
    final today = dateOnly(DateTime.now());
    final active = getSubscriptions().where((s) => s.isActive).toList();
    return DashboardSummary(
      totalMonthly: costCalculator.getTotalMonthlySpending(active),
      upcomingPayments: subscriptionService.getUpcomingSubscriptions(today),
      activeSubscriptions: active,
      reviewCount: reviewService.getSubscriptionsForReview().length,
    );
  }

  void _ensureValid(SubscriptionData data) {
    final result = validate(data);
    if (!result.valid) throw ValidationException(result);
  }

  Subscription _build({
    required String id,
    required SubscriptionData data,
    required double price,
    required DateTime date,
    required String? logoPath,
    required SubscriptionStatus status,
  }) {
    return Subscription(
      id: id,
      name: data.name.trim(),
      category: data.category,
      price: price,
      billingCycle: data.billingCycle,
      nextPaymentDate: dateOnly(date),
      logoPath: logoPath,
      isShared: data.isShared,
      numberOfPeople: data.isShared ? data.numberOfPeople : 1,
      status: status,
    );
  }
}
