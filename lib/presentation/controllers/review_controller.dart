import '../../data_access/models/review_record.dart';
import '../../data_access/models/subscription.dart';
import '../../review_management/review_service.dart';
import '../data_refresh.dart';

/// LLD class: ReviewController. Receives taps from the Review screens.
class ReviewController {
  ReviewController({required this.reviewService, required this.refresh});

  final ReviewService reviewService;
  final DataRefresh refresh;

  /// Subscriptions waiting for a decision (Figure 4).
  List<Subscription> getReviewList() => reviewService.getSubscriptionsForReview();

  Future<ReviewRecord> keep(String subscriptionId) async {
    final record = await reviewService.keepSubscription(subscriptionId);
    refresh.notifyChanged();
    return record;
  }

  Future<ReviewRecord> reviewLater(String subscriptionId, int days) async {
    final record = await reviewService.reviewLater(subscriptionId, days);
    refresh.notifyChanged();
    return record;
  }

  Future<ReviewRecord> stopTracking(String subscriptionId) async {
    final record = await reviewService.stopTracking(subscriptionId);
    refresh.notifyChanged();
    return record;
  }

  /// Added: the "Remind me again in..." choices (1, 3 and 5 days).
  List<int> getReminderOptions() =>
      reviewService.reviewPolicy.getReminderOptions();

  /// Added: called when the app comes back to the screen, so payment dates
  /// that passed while it was closed are recorded.
  Future<void> refreshDuePayments() async {
    await reviewService.processDuePayments();
    refresh.notifyChanged();
  }
}
