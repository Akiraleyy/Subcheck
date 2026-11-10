import '../../data_access/models/calendar_entry.dart';
import '../../review_management/calendar_service.dart';

/// LLD class: CalendarController. Gives the Calendar screen its entries.
class CalendarController {
  CalendarController({required this.calendarService});

  final CalendarService calendarService;

  /// Everything to draw for the month of [month]: paid + upcoming + missed.
  List<CalendarEntry> getCalendar(DateTime month) {
    return [
      ...calendarService.getPaymentHistory(month),
      ...calendarService.getUpcomingPayments(month),
      ...calendarService.getMissedReviews(month),
    ];
  }
}
