import 'dart:math';

import 'package:intl/intl.dart';

import '../data_access/models/enums.dart';

/// Small helper functions used by many files.

/// Makes a random UUID such as "3f2b8c1e-5d4a-4b7e-9c10-2a6f8d3e1b45".
/// Every record (subscription, review, payment, reminder) gets one as its id.
String newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // marks it as a version-4 UUID
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Removes the time of day so two dates can be compared fairly.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Adds (or subtracts) whole calendar days.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Whole days from [from] to [to] (negative if [to] is earlier).
/// Uses UTC so daylight-saving changes can never give an off-by-one.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// Adds months and keeps the day valid (Jan 31 + 1 month = Feb 28 or 29).
DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final year = d.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDayOfMonth ? lastDayOfMonth : d.day);
}

/// The date of the payment after [d] for a given billing cycle.
DateTime addCycle(DateTime d, BillingCycle cycle) {
  switch (cycle) {
    case BillingCycle.weekly:
      return addDays(d, 7);
    case BillingCycle.monthly:
      return addMonths(d, 1);
    case BillingCycle.yearly:
      return addMonths(d, 12);
  }
}

/// Formats money as pesos, e.g. "₱1,234.50". With [trimWhole] a whole amount
/// is shown without cents, e.g. "₱956".
String peso(double value, {bool trimWhole = false}) {
  if (trimWhole && value == value.roundToDouble()) {
    return '₱${NumberFormat('#,##0').format(value)}';
  }
  return '₱${NumberFormat('#,##0.00').format(value)}';
}
