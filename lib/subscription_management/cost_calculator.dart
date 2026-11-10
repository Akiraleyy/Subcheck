import '../data_access/models/enums.dart';
import '../data_access/models/subscription.dart';

/// LLD class: CostCalculator. Works out the money. It has no state, so it is
/// safe to create anywhere with `const CostCalculator()`.
class CostCalculator {
  const CostCalculator();

  /// The user's own share. A shared subscription is split equally between the
  /// number of people; otherwise the user pays the full price.
  double getUserShare(Subscription subscription) {
    if (subscription.isShared && subscription.numberOfPeople > 1) {
      return subscription.price / subscription.numberOfPeople;
    }
    return subscription.price;
  }

  /// The user's share turned into a cost per month, whatever the billing cycle:
  /// weekly x 52 / 12, monthly as is, yearly / 12.
  double getMonthlyCost(Subscription subscription) {
    final share = getUserShare(subscription);
    switch (subscription.billingCycle) {
      case BillingCycle.weekly:
        return share * 52 / 12;
      case BillingCycle.monthly:
        return share;
      case BillingCycle.yearly:
        return share / 12;
    }
  }

  /// Total monthly spending. Stopped subscriptions are not counted.
  double getTotalMonthlySpending(List<Subscription> subscriptions) {
    var total = 0.0;
    for (final s in subscriptions) {
      if (s.isActive) total += getMonthlyCost(s);
    }
    return total;
  }
}
