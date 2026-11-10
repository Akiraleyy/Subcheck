import '../data_access/models/subscription.dart';
import '../utils/helpers.dart';

/// LLD class: ReviewPolicy. The rules for WHEN a review is needed.
/// Keeping them in one small class makes them easy to change and to test.
class ReviewPolicy {
  const ReviewPolicy();

  /// A review is needed when the payment is this many days away (or fewer).
  int getReviewWindowDays() => 7;

  /// True when the subscription is active and its payment is today or within
  /// the review window. [today] is passed in so tests can use any date.
  bool needsReview(Subscription subscription, DateTime today) {
    if (!subscription.isActive) return false;
    final days = daysBetween(today, subscription.nextPaymentDate);
    return days >= 0 && days <= getReviewWindowDays();
  }

  /// The choices shown in "Remind me again in..." (Figure 6): tomorrow,
  /// in 3 days and in 5 days.
  List<int> getReminderOptions() => const [1, 3, 5];
}
