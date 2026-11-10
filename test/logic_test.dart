import 'package:flutter_test/flutter_test.dart';
import 'package:subcheck/data_access/models/enums.dart';
import 'package:subcheck/data_access/models/subscription.dart';
import 'package:subcheck/review_management/review_policy.dart';
import 'package:subcheck/subscription_management/cost_calculator.dart';
import 'package:subcheck/utils/helpers.dart';

/// Tests for the pure calculation rules (no phone, no storage needed).
/// Run them with:  flutter test
Subscription sub({
  double price = 300,
  BillingCycle cycle = BillingCycle.monthly,
  bool shared = false,
  int people = 1,
  DateTime? next,
  SubscriptionStatus status = SubscriptionStatus.active,
}) {
  return Subscription(
    id: 'x',
    name: 'Test',
    category: Category.entertainment,
    price: price,
    billingCycle: cycle,
    nextPaymentDate: next ?? DateTime(2026, 11, 10),
    isShared: shared,
    numberOfPeople: people,
    status: status,
  );
}

void main() {
  group('CostCalculator', () {
    const calc = CostCalculator();

    test('user pays the full price when not shared', () {
      expect(calc.getUserShare(sub(price: 300)), 300);
    });

    test('shared price is split between the people', () {
      expect(calc.getUserShare(sub(price: 300, shared: true, people: 3)), 100);
    });

    test('yearly is divided by 12 and weekly is scaled to a month', () {
      expect(calc.getMonthlyCost(sub(price: 1200, cycle: BillingCycle.yearly)), 100);
      expect(
        calc.getMonthlyCost(sub(price: 100, cycle: BillingCycle.weekly)),
        closeTo(100 * 52 / 12, 0.0001),
      );
    });

    test('total ignores stopped subscriptions', () {
      final total = calc.getTotalMonthlySpending([
        sub(price: 100),
        sub(price: 200, status: SubscriptionStatus.stopped),
      ]);
      expect(total, 100);
    });
  });

  group('ReviewPolicy', () {
    const policy = ReviewPolicy();
    final today = DateTime(2026, 11, 8);

    test('review window is 7 days and options are 1, 3, 5', () {
      expect(policy.getReviewWindowDays(), 7);
      expect(policy.getReminderOptions(), [1, 3, 5]);
    });

    test('needs review when payment is within 7 days', () {
      expect(policy.needsReview(sub(next: DateTime(2026, 11, 8)), today), isTrue);
      expect(policy.needsReview(sub(next: DateTime(2026, 11, 15)), today), isTrue);
    });

    test('does not need review when too far away, already past, or stopped', () {
      expect(policy.needsReview(sub(next: DateTime(2026, 11, 16)), today), isFalse);
      expect(policy.needsReview(sub(next: DateTime(2026, 11, 7)), today), isFalse);
      expect(
        policy.needsReview(
            sub(next: DateTime(2026, 11, 10), status: SubscriptionStatus.stopped),
            today),
        isFalse,
      );
    });
  });

  group('date helpers', () {
    test('monthly cycle clamps to the last day of a short month', () {
      expect(addCycle(DateTime(2026, 1, 31), BillingCycle.monthly),
          DateTime(2026, 2, 28));
    });

    test('weekly and yearly cycles', () {
      expect(addCycle(DateTime(2026, 11, 8), BillingCycle.weekly),
          DateTime(2026, 11, 15));
      expect(addCycle(DateTime(2026, 11, 8), BillingCycle.yearly),
          DateTime(2027, 11, 8));
    });

    test('daysBetween counts whole days', () {
      expect(daysBetween(DateTime(2026, 11, 8), DateTime(2026, 11, 15)), 7);
      expect(daysBetween(DateTime(2026, 11, 8), DateTime(2026, 11, 7)), -1);
    });

    test('peso formatting', () {
      expect(peso(1234.5), '₱1,234.50');
      expect(peso(956, trimWhole: true), '₱956');
    });
  });
}
