import 'local_database.dart';
import 'models/reminder.dart';

/// LLD class: ReminderRepository. Saves and loads planned reminders.
class ReminderRepository {
  ReminderRepository(this._db);

  final LocalDatabase _db;
  static const _table = 'reminders';
  List<Reminder> _items = [];

  void load() {
    _items = [];
    for (final row in _db.readTable(_table)) {
      try {
        _items.add(Reminder.fromJson(row));
      } catch (_) {}
    }
  }

  Future<void> _persist() =>
      _db.writeTable(_table, _items.map((r) => r.toJson()).toList());

  Future<Reminder> insert(Reminder reminder) async {
    _items.add(reminder);
    await _persist();
    return reminder;
  }

  /// Added: used to mark a reminder as sent.
  Future<bool> update(Reminder reminder) async {
    final index = _items.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return false;
    _items[index] = reminder;
    await _persist();
    return true;
  }

  /// Deletes a subscription's reminders. If [type] is given, only that kind.
  Future<bool> deleteBySubscription(String subscriptionId, {String? type}) async {
    final before = _items.length;
    _items.removeWhere((r) =>
        r.subscriptionId == subscriptionId && (type == null || r.type == type));
    if (_items.length == before) return false;
    await _persist();
    return true;
  }

  Future<void> deleteAll() async {
    _items = [];
    await _persist();
  }

  /// Reminders whose time has come and that are not marked as sent yet.
  List<Reminder> findDue(DateTime now) =>
      _items.where((r) => !r.isSent && !r.scheduledDate.isAfter(now)).toList();

  List<Reminder> findBySubscription(String subscriptionId) =>
      _items.where((r) => r.subscriptionId == subscriptionId).toList();

  List<Reminder> findAll() => List.of(_items);
}
