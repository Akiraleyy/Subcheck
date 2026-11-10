/// The "Enumerations" box of the Low-Level Design (Figure 2).
/// An enumeration is a fixed list of allowed values.
library;

enum Category { entertainment, music, cloudStorage, software, fitness, shopping }

extension CategoryLabel on Category {
  /// The text shown on screen.
  String get label => switch (this) {
        Category.entertainment => 'Entertainment',
        Category.music => 'Music',
        Category.cloudStorage => 'Cloud Storage',
        Category.software => 'Software',
        Category.fitness => 'Fitness',
        Category.shopping => 'Shopping',
      };
}

enum BillingCycle { weekly, monthly, yearly }

extension BillingCycleLabel on BillingCycle {
  String get label => switch (this) {
        BillingCycle.weekly => 'Weekly',
        BillingCycle.monthly => 'Monthly',
        BillingCycle.yearly => 'Yearly',
      };

  /// Used in "₱169.00 / month".
  String get unit => switch (this) {
        BillingCycle.weekly => 'week',
        BillingCycle.monthly => 'month',
        BillingCycle.yearly => 'year',
      };
}

enum SubscriptionStatus { active, stopped }

enum ReviewDecision { keep, reviewLater, stopTracking }

enum EntryType { paid, upcoming, missedReview }
