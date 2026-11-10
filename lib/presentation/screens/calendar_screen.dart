import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data_access/models/calendar_entry.dart';
import '../../data_access/models/enums.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/subscription_controller.dart';
import '../data_refresh.dart';
import '../widgets/common.dart';
import 'subscription_details_screen.dart';

/// Figure 8. Calendar. Paid = green, Upcoming = lime, Missed review = red.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;

  void _changeMonth(int by) {
    setState(() {
      _month = DateTime(_month.year, _month.month + by);
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<DataRefresh>();
    final entries = context.read<CalendarController>().getCalendar(_month);

    // Group the entries by day so each day can be coloured.
    final byDate = <DateTime, List<CalendarEntry>>{};
    for (final entry in entries) {
      byDate.putIfAbsent(dateOnly(entry.date), () => []).add(entry);
    }

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // DateTime.weekday: Monday = 1 ... Sunday = 7. The grid starts on Sunday,
    // so "% 7" gives the number of empty cells before day 1.
    final blanks = _month.weekday % 7;
    final today = dateOnly(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('Calendar',
            style: TextStyle(
                color: context.ink, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),

        // Month name with previous / next arrows
        Row(children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(Icons.chevron_left, color: context.ink),
          ),
          Expanded(
            child: Center(
              child: Text(DateFormat('MMMM yyyy').format(_month),
                  style: TextStyle(
                      color: context.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 17)),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(Icons.chevron_right, color: context.ink),
          ),
        ]),
        const SizedBox(height: 8),

        // S M T W T F S
        Row(children: [
          for (final letter in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
            Expanded(
              child: Center(
                child: Text(letter,
                    style: TextStyle(
                        color: context.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ),
        ]),
        const SizedBox(height: 8),

        // The days
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          children: [
            for (var i = 0; i < blanks; i++) const SizedBox(),
            for (var day = 1; day <= daysInMonth; day++)
              _dayCell(context, DateTime(_month.year, _month.month, day),
                  byDate, today),
          ],
        ),

        // Details of the tapped day
        if (_selected != null) ..._selectedDay(context, byDate),

        const SizedBox(height: 20),
        Text('Legend',
            style: TextStyle(
                color: context.ink, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 6),
        _legend(context, AppColors.green, 'Paid'),
        _legend(context, AppColors.lime, 'Upcoming'),
        _legend(context, AppColors.red, 'Missed review'),
      ],
    );
  }

  Widget _dayCell(BuildContext context, DateTime date,
      Map<DateTime, List<CalendarEntry>> byDate, DateTime today) {
    final types = (byDate[date] ?? []).map((e) => e.type).toSet();

    // If several things happen on one day, the most important colour wins:
    // missed review > upcoming > paid.
    Color? fill;
    var textColor = context.ink;
    if (types.contains(EntryType.missedReview)) {
      fill = AppColors.red;
      textColor = Colors.white;
    } else if (types.contains(EntryType.upcoming)) {
      fill = AppColors.lime;
      textColor = AppColors.purple;
    } else if (types.contains(EntryType.paid)) {
      fill = AppColors.green;
      textColor = Colors.white;
    }

    final isToday = date == today;
    final isSelected = _selected != null && dateOnly(_selected!) == date;

    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: context.ink, width: 2)
                : isToday
                    ? Border.all(color: context.cardBorder, width: 1.5)
                    : null,
          ),
          child: Text('${date.day}',
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ),
    );
  }

  List<Widget> _selectedDay(
      BuildContext context, Map<DateTime, List<CalendarEntry>> byDate) {
    final entries = byDate[dateOnly(_selected!)] ?? [];
    final controller = context.read<SubscriptionController>();
    final tiles = <Widget>[];

    for (final entry in entries) {
      final s = controller.getSubscription(entry.subscriptionId);
      if (s == null) continue;
      tiles.add(SubTile(
        subscription: s,
        subtitle: switch (entry.type) {
          EntryType.paid => 'Paid',
          EntryType.upcoming => 'Upcoming payment',
          EntryType.missedReview => 'Review missed',
        },
        amount: peso(s.yourShare),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SubscriptionDetailsScreen(subscriptionId: s.id)),
        ),
      ));
    }

    return [
      SectionTitle(DateFormat.yMMMMd().format(_selected!)),
      if (tiles.isEmpty)
        Text('Nothing on this day.', style: TextStyle(color: context.muted)),
      ...tiles,
    ];
  }

  Widget _legend(BuildContext context, Color color, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: context.muted, fontSize: 12)),
        ]),
      );
}
