import 'enums.dart';

/// LLD class: CalendarEntry. One coloured dot on the calendar.
class CalendarEntry {
  const CalendarEntry({
    required this.date,
    required this.subscriptionId,
    required this.type,
  });

  final DateTime date;
  final String subscriptionId;
  final EntryType type;
}
