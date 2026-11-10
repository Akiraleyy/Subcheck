import '../data_access/models/calendar_entry.dart';
import '../data_access/models/enums.dart';
import '../data_access/payment_repository.dart';
import '../data_access/review_repository.dart';
import '../data_access/subscription_repository.dart';
import '../utils/helpers.dart';

/// LLD class: CalendarService. Prepares the dots shown on the Calendar
/// (Figure 8): paid (green), upcoming (lime) and missed review (red).
class CalendarService {
  CalendarService({
    required this.paymentRepository,
    required this.reviewRepository,
    required this.subscriptionRepository,
  });

  final PaymentRepository paymentRepository;
  final ReviewRepository reviewRepository;

  /// Added: upcoming payments are worked out from the active subscriptions.
  final SubscriptionRepository subscriptionRepository;

  /// Payment dates still to come in the month of [month]. A weekly
  /// subscription can appear several times in one month.
  List<CalendarEntry> getUpcomingPayments(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final entries = <CalendarEntry>[];

    for (final s in subscriptionRepository.findAll().where((s) => s.isActive)) {
      var date = dateOnly(s.nextPaymentDate);
      var guard = 0;
      while (!date.isAfter(last) && guard < 400) {
        if (!date.isBefore(first)) {
          entries.add(CalendarEntry(
              date: date, subscriptionId: s.id, type: EntryType.upcoming));
        }
        date = addCycle(date, s.billingCycle);
        guard++;
      }
    }
    return entries;
  }

  /// Payments already made in the month of [month].
  List<CalendarEntry> getPaymentHistory(DateTime month) {
    return paymentRepository
        .findByMonth(month)
        .where((p) => p.isPaid)
        .map((p) => CalendarEntry(
            date: dateOnly(p.paymentDate),
            subscriptionId: p.subscriptionId,
            type: EntryType.paid))
        .toList();
  }

  /// Reviews the user missed in the month of [month].
  List<CalendarEntry> getMissedReviews(DateTime month) {
    return reviewRepository
        .findMissed()
        .where((r) =>
            r.paymentDate.year == month.year &&
            r.paymentDate.month == month.month)
        .map((r) => CalendarEntry(
            date: dateOnly(r.paymentDate),
            subscriptionId: r.subscriptionId,
            type: EntryType.missedReview))
        .toList();
  }
}
