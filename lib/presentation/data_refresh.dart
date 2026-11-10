import 'package:flutter/foundation.dart';

/// A tiny "something changed" signal. Controllers call [notifyChanged] after
/// every add / edit / review / delete, and every screen that watches it
/// redraws. That is how the dashboard total, the review banner and the
/// calendar all update immediately (a non-functional requirement).
class DataRefresh extends ChangeNotifier {
  void notifyChanged() => notifyListeners();
}
