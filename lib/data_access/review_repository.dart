import 'local_database.dart';
import 'models/review_record.dart';

/// LLD class: ReviewRepository. Saves and loads review decisions.
class ReviewRepository {
  ReviewRepository(this._db);

  final LocalDatabase _db;
  static const _table = 'review_records';
  List<ReviewRecord> _items = [];

  void load() {
    _items = [];
    for (final row in _db.readTable(_table)) {
      try {
        _items.add(ReviewRecord.fromJson(row));
      } catch (_) {}
    }
  }

  Future<void> _persist() =>
      _db.writeTable(_table, _items.map((r) => r.toJson()).toList());

  Future<ReviewRecord> insert(ReviewRecord record) async {
    _items.add(record);
    await _persist();
    return record;
  }

  List<ReviewRecord> findBySubscription(String subscriptionId) =>
      _items.where((r) => r.subscriptionId == subscriptionId).toList();

  /// Reviews the user never answered before the payment date.
  List<ReviewRecord> findMissed() => _items.where((r) => r.isMissed).toList();

  List<ReviewRecord> findAll() => List.of(_items);

  /// Added: used when a subscription is deleted, so no leftovers remain.
  Future<bool> deleteBySubscription(String subscriptionId) async {
    final before = _items.length;
    _items.removeWhere((r) => r.subscriptionId == subscriptionId);
    if (_items.length == before) return false;
    await _persist();
    return true;
  }

  Future<void> replaceAll(List<ReviewRecord> items) async {
    _items = List.of(items);
    await _persist();
  }
}
