import 'subscription.dart';

/// LLD class: DashboardSummary. Everything the Home screen needs in one object.
class DashboardSummary {
  const DashboardSummary({
    required this.totalMonthly,
    required this.upcomingPayments,
    required this.activeSubscriptions,
    required this.reviewCount,
  });

  /// Total monthly spending (the user's share of every active subscription).
  final double totalMonthly;

  /// Active subscriptions due soon (within 14 days).
  final List<Subscription> upcomingPayments;

  /// All active subscriptions.
  final List<Subscription> activeSubscriptions;

  /// How many subscriptions need a Keep / Review later / Stop decision.
  final int reviewCount;

  /// Active subscriptions that are not already listed under "Upcoming".
  /// The Home screen shows these under "Active subscriptions" (Figure 1).
  List<Subscription> get otherActive => activeSubscriptions
      .where((s) => !upcomingPayments.any((u) => u.id == s.id))
      .toList();
}
