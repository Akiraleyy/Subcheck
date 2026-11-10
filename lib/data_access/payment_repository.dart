import 'local_database.dart';
import 'models/payment_record.dart';

/// LLD class: PaymentRepository. Saves and loads past payments.
class PaymentRepository {
  PaymentRepository(this._db);

  final LocalDatabase _db;
  static const _table = 'payment_records';
  List<PaymentRecord> _items = [];

  void load() {
    _items = [];
    for (final row in _db.readTable(_table)) {
      try {
        _items.add(PaymentRecord.fromJson(row));
      } catch (_) {}
    }
  }

  Future<void> _persist() =>
      _db.writeTable(_table, _items.map((p) => p.toJson()).toList());

  Future<PaymentRecord> insert(PaymentRecord payment) async {
    _items.add(payment);
    await _persist();
    return payment;
  }

  /// All payments that fall in the same month as [month].
  List<PaymentRecord> findByMonth(DateTime month) => _items
      .where((p) =>
          p.paymentDate.year == month.year &&
          p.paymentDate.month == month.month)
      .toList();

  List<PaymentRecord> findBySubscription(String subscriptionId) =>
      _items.where((p) => p.subscriptionId == subscriptionId).toList();

  List<PaymentRecord> findAll() => List.of(_items);

  Future<bool> deleteBySubscription(String subscriptionId) async {
    final before = _items.length;
    _items.removeWhere((p) => p.subscriptionId == subscriptionId);
    if (_items.length == before) return false;
    await _persist();
    return true;
  }

  Future<void> replaceAll(List<PaymentRecord> items) async {
    _items = List.of(items);
    await _persist();
  }
}
