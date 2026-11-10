import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data_access/models/enums.dart';
import '../../data_access/models/subscription.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';
import '../controllers/subscription_controller.dart';
import '../data_refresh.dart';
import '../widgets/common.dart';
import 'add_subscription_screen.dart';

/// Figure 7. Subscription Details, with Edit and Remove.
class SubscriptionDetailsScreen extends StatelessWidget {
  const SubscriptionDetailsScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    context.watch<DataRefresh>();
    final s =
        context.read<SubscriptionController>().getSubscription(subscriptionId);
    // The subscription was deleted: nothing to show.
    if (s == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Big card: logo, name, category, price
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.cardBorder)),
                      child: Column(children: [
                        SubLogo(path: s.logoPath, size: 56),
                        const SizedBox(height: 10),
                        Text(s.name,
                            style: TextStyle(
                                color: context.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                        Text(s.category.label,
                            style:
                                TextStyle(color: context.muted, fontSize: 12)),
                        const SizedBox(height: 10),
                        Text('${peso(s.price)}/${s.billingCycle.unit}',
                            style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w900,
                                fontSize: 24)),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Table of details
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.cardBorder)),
                      child: Column(children: [
                        _row(context, 'Category', s.category.label),
                        _row(context, 'Billing cycle', s.billingCycle.label),
                        _row(context, 'Next payment',
                            DateFormat.yMMMd().format(s.nextPaymentDate)),
                        _row(context, 'Shared subscription',
                            s.isShared ? 'Yes' : 'No',
                            last: !s.isShared),
                        if (s.isShared) ...[
                          _row(context, 'People sharing', '${s.numberOfPeople}'),
                          _row(context, 'Your share', peso(s.yourShare),
                              last: true),
                        ],
                      ]),
                    ),

                    if (!s.isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'You stopped tracking this subscription. Remember to '
                          'cancel it with the service itself.',
                          style: TextStyle(color: context.muted),
                        ),
                      ),
                  ],
                ),
              ),

              // Edit
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddSubscriptionScreen(existing: s)),
                ),
                child: const Text('Edit subscription'),
              ),
              const SizedBox(height: 10),

              // Remove
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _remove(context, s),
                  child: const Text('Remove subscription',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, Subscription s) async {
    final controller = context.read<SubscriptionController>();
    final navigator = Navigator.of(context);
    final confirmed = await confirmDialog(
      context,
      title: 'Remove ${s.name}?',
      message: 'This deletes it and its history from this device.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await controller.deleteSubscription(s.id);
    if (!context.mounted) return;
    showSnack(context, '${s.name} removed.');
    navigator.pop();
  }

  Widget _row(BuildContext context, String label, String value,
      {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.cardBorder)),
      ),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(color: context.muted, fontSize: 13))),
        Text(value,
            style: TextStyle(
                color: context.ink, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    );
  }
}
