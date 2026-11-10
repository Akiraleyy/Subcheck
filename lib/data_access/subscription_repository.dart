import 'local_database.dart';
import 'models/subscription.dart';

/// LLD class: SubscriptionRepository. Saves and loads subscriptions.
///
/// The list is kept in memory so screens can read it instantly; every change
/// is also written to the phone before the method finishes.
/// (In the LLD the methods show plain return types. In Dart anything that
/// writes to storage returns a Future, so you `await` it.)
class SubscriptionRepository {
  SubscriptionRepository(this._db);

  final LocalDatabase _db;
  static const _table = 'subscriptions';
  List<Subscription> _items = [];

  /// Loads everything saved on the phone. Called once at start-up.
  void load() {
    _items = [];
    for (final row in _db.readTable(_table)) {
      try {
        _items.add(Subscription.fromJson(row));
      } catch (_) {
        // A damaged row is skipped instead of crashing the app.
      }
    }
  }

  Future<void> _persist() =>
      _db.writeTable(_table, _items.map((s) => s.toJson()).toList());

  Future<Subscription> insert(Subscription subscription) async {
    _items.add(subscription);
    await _persist();
    return subscription;
  }

  Future<bool> update(Subscription subscription) async {
    final index = _items.indexWhere((s) => s.id == subscription.id);
    if (index == -1) return false;
    _items[index] = subscription;
    await _persist();
    return true;
  }

  Future<bool> delete(String id) async {
    final before = _items.length;
    _items.removeWhere((s) => s.id == id);
    if (_items.length == before) return false;
    await _persist();
    return true;
  }

  Subscription? findById(String id) {
    for (final s in _items) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Subscription> findAll() => List.of(_items);

  /// Used when restoring a backup.
  Future<void> replaceAll(List<Subscription> items) async {
    _items = List.of(items);
    await _persist();
  }
}
