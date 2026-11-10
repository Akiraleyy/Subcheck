import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data_access/models/enums.dart';
import '../../data_access/models/subscription.dart';

import '../../theme.dart';
import '../../utils/helpers.dart';
import '../controllers/subscription_controller.dart';
import '../data_refresh.dart';
import '../widgets/common.dart';
import 'subscription_details_screen.dart';


/// Figure 1. Home Dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate, required this.onAdd});

  /// Switches the bottom tab (2 = Review).
  final ValueChanged<int> onNavigate;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    // Watching DataRefresh makes this screen redraw after any change.
    context.watch<DataRefresh>();
    final summary =
        context.read<SubscriptionController>().getDashboardSummary();
    final today = DateTime.now();

    void open(Subscription s) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SubscriptionDetailsScreen(subscriptionId: s.id)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('SubCheck',
            style: TextStyle(
                color: context.ink, fontSize: 22, fontWeight: FontWeight.w900)),
        Text('Hi there', style: TextStyle(color: context.muted, fontSize: 13)),
        const SizedBox(height: 14),

        // Total monthly spending card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: AppColors.purple, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total monthly spending',
                  style: TextStyle(color: AppColors.lime, fontSize: 12)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [
                TextSpan(
                  text: peso(summary.totalMonthly, trimWhole: true),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900),
                ),
                const TextSpan(
                  text: '/month',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ])),
            ],
          ),
        ),

        // "N subscriptions need review" notice. Tapping opens the Review tab.
        if (summary.reviewCount > 0) ...[
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onNavigate(2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.darkSurface : AppColors.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.notifications_none, size: 18, color: context.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.reviewCount == 1
                        ? '1 subscription needs review'
                        : '${summary.reviewCount} subscriptions need review',
                    style: TextStyle(
                        color: context.ink, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right, color: context.ink),
              ]),
            ),
          ),
        ],

        // Empty state
        if (summary.activeSubscriptions.isEmpty) ...[
          const SizedBox(height: 48),
          Icon(Icons.subscriptions_outlined, size: 56, color: context.muted),
          const SizedBox(height: 12),
          Center(
            child: Text('No subscriptions yet',
                style: TextStyle(
                    color: context.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('Add one to start tracking your renewals.',
                style: TextStyle(color: context.muted)),
          ),
        ],

        if (summary.upcomingPayments.isNotEmpty) ...[
          const SectionTitle('Upcoming payments'),
          for (final s in summary.upcomingPayments)
            SubTile(
              subscription: s,
              subtitle: _dueText(daysBetween(today, s.nextPaymentDate)),
              amount: peso(s.yourShare),
              onTap: () => open(s),
            ),
        ],

        if (summary.otherActive.isNotEmpty) ...[
          const SectionTitle('Active subscriptions'),
          for (final s in summary.otherActive)
            SubTile(
              subscription: s,
              subtitle: s.billingCycle.label,
              amount: peso(s.yourShare),
              onTap: () => open(s),
            ),
        ],

        const SizedBox(height: 8),
        ElevatedButton(
            onPressed: onAdd, child: const Text('+ Add subscription')),
      ],
    );
  }

  static String _dueText(int days) {
    if (days <= 0) return 'due today';
    if (days == 1) return 'due tomorrow';
    return 'due in $days days';
  }
}
