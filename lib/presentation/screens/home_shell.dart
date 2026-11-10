import 'package:flutter/material.dart';

import '../../theme.dart';
import 'add_subscription_screen.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

/// The frame around the four main tabs: Home, Calendar, Review, Settings,
/// with the round lime "+" button in the middle that opens Add Subscription.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  void _openAdd() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // IndexedStack keeps all four tabs alive, so each remembers its state.
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(onNavigate: _goTo, onAdd: _openAdd),
            const CalendarScreen(),
            const ReviewScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      // The "+" button lives INSIDE the bar (no floating button), so it sits
      // on the same line as Home, Calendar, Review and Settings.
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            _item(0, Icons.home_outlined, Icons.home, 'Home'),
            _item(1, Icons.calendar_month_outlined, Icons.calendar_month,
                'Calendar'),
            _addButton(),
            _item(2, Icons.checklist_rtl, Icons.checklist_rtl, 'Review'),
            _item(3, Icons.settings_outlined, Icons.settings, 'Settings'),
          ],
        ),
      ),
    );
  }

  /// The round lime "+" button, centred in the bar like the other items.
  Widget _addButton() {
    return Expanded(
      child: Center(
        child: Tooltip(
          message: 'Add subscription',
          child: Material(
            color: AppColors.lime,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _openAdd,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.add, size: 28, color: AppColors.purple),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, IconData selectedIcon, String label) {
    final selected = _index == index;
    final color = selected ? context.ink : context.muted;
    return Expanded(
      child: InkWell(
        onTap: () => _goTo(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}